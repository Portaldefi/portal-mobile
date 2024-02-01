//
//  SwapViewModel.swift
//  Portal
//
//  Created by farid on 20.12.2023.
//

import Foundation
import PortalSwapSDK
import Combine
import Factory

@Observable class SwapViewModel {
    enum SwapState: Comparable {
        case start, publishOrder, matchingOrder, orderMatched, swapping, swapSucceed, swapError(String)
    }
    
    var bottomOffset: CGFloat = 65
    var exchangerSide: Exchanger.Side = .base
    
    var base: Coin = .lightningBitcoin()
    var quote: Coin = .ethereum()
        
    private var contractFileName: String {
        switch config.network {
        case .playnet:
            return "playnetContract"
        case .testnet:
            return "sepoliaContract"
        case .mainnet:
            fatalError("Not impemented")
        }
    }
    
    private let swapTimeoutTimer = RepeatingTimer(timeInterval: 1)
    private var swapTimeoutCountDown = 120
    
    var swapState: SwapState = .start {
        didSet {
            switch swapState {
            case .matchingOrder:
                swapTimeoutTimer.suspend()
            case .swapping:
                swapTimeoutCountDown = 180
                swapTimeoutTimer.resume()
                
                swapTimeoutTimer.eventHandler = { [unowned self] in
                    guard swapTimeoutCountDown == 0 else {
                        swapTimeoutCountDown-=1
                        return
                    }
                    swapTimeoutTimer.suspend()
                    swapState = .swapError("Swap timeout")
                }
            case .swapSucceed:
                swapTimeoutTimer.suspend()
                if let sdk = sdk, sdk.isConnected {
                    _ = sdk.stop()
                }
            case .swapError:
                swapTimeoutTimer.suspend()
                if let sdk = sdk, sdk.isConnected {
                    _ = sdk.stop()
                }
            default:
                break
            }
        }
    }
    
    var timeoutString: String {
        let minutes = Int(swapTimeoutCountDown) / 60
        let seconds = Int(swapTimeoutCountDown) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var orderSide: Order.OrderSide = .ask {
        didSet {
            print("Order side: \(orderSide.rawValue)")
        }
    }
    
    var baseAmount = String() {
        willSet {
            guard let decimalAmount = Decimal(string: newValue) else { return }
            baseAmountPublisher.send(decimalAmount)
        }
    }
    
    var baseAmountValue: String {
        guard baseAmountPublisher.value > 0 else { return "0" }
        
        let currentPrice: Decimal
        
        switch base.type {
        case .bitcoin, .lightningBitcoin:
            currentPrice = marketData.lastSeenBtcPrice
        case .ethereum, .erc20:
            currentPrice = marketData.lastSeenEthPrice
        }
        
        return (baseAmountPublisher.value * currentPrice).double.usdFormatted()
    }
    
    var quoteAmount = String() {
        willSet {
            guard let decimalAmount = Decimal(string: newValue) else { return }
            quoteAmountPublisher.send(decimalAmount)
        }
    }
    
    var quoteAmountValue: String {
        guard quoteAmountPublisher.value > 0 else { return "0" }
        
        let currentPrice: Decimal
        
        switch quote.type {
        case .bitcoin, .lightningBitcoin:
            currentPrice = marketData.lastSeenBtcPrice
        case .ethereum, .erc20:
            currentPrice = marketData.lastSeenEthPrice
        }
        
        return (quoteAmountPublisher.value * currentPrice).double.usdFormatted()
    }
    
    var actionButtonEnabled = false
    
    var baseBalanceString: String {
        String(describing: baseBalance.formatted())
    }
    
    var quoteBalanceString: String {
        String(describing: quoteBalance.formatted())
    }
    
    private var baseBalance: Decimal {
        guard let balanceAdapter = adapterManager.adapter(for: base) as? IBalanceAdapter else { return 0 }
        return balanceAdapter.balance
    }
    
    private var quoteBalance: Decimal {
        guard let balanceAdapter = adapterManager.adapter(for: quote) as? IBalanceAdapter else { return 0 }
        return balanceAdapter.balance
    }
        
    @ObservationIgnored private var sdk: SDK?
    @ObservationIgnored private var adapterManager: IAdapterManager
    @ObservationIgnored private var marketData: IMarketDataRepository
    @ObservationIgnored private var subscriptions = Set<AnyCancellable>()
    @ObservationIgnored private var baseAmountPublisher = CurrentValueSubject<Decimal, Never>(0)
    @ObservationIgnored private var quoteAmountPublisher = CurrentValueSubject<Decimal, Never>(0)
    
    @ObservationIgnored var order: PortalSwapSDK.Order?
    var orders: [PortalSwapSDK.Order] = []
    
    private let config = Container.configProvider()
    
    init() {
        self.adapterManager = Container.adapterManager()
        self.marketData = Container.marketData()
        
        let evmKitManager = Container.ethereumKitManager()
        let lightningManager = Container.lightningKitManager()
        
        guard let privKey = evmKitManager.key else {
            swapState = .swapError("swap sdk, error: evm key is missing")
            return
        }
        guard let lightningKitManager = lightningManager as? ILightningClient else {
            swapState = .swapError("swap sdk, error: lightning client is missing")
            return
        }
                
        do {
            try setupSDK(ethPrivKey: privKey, lightningClient: lightningKitManager)
        } catch {
            swapState = .swapError("SDK setup error: \(error)")
        }
        
        self.setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        Publishers.CombineLatest(baseAmountPublisher, quoteAmountPublisher)
            .dropFirst()
            .sink { [unowned self] (baseAmt, quoteAmt) in
                actionButtonEnabled = baseAmt > 0 && baseAmt < baseBalance && quoteAmt > 0 && quoteAmt < quoteBalance
            }
            .store(in: &subscriptions)
        
        guard let sdk = sdk else { return }
        
        sdk.addListener(event: "swap.received", action: { _ in
            DispatchQueue.main.async {
                self.swapState = .orderMatched
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.swapState = .swapping
            }
        })
        
        sdk.addListener(event: "swap.completed", action: { _ in
            DispatchQueue.main.async {
                self.swapState = .swapSucceed
            }
        })
        
        sdk.addListener(event: "error", action: { args in
            DispatchQueue.main.async {
                self.swapState = .swapError("Swap error: \(args.first ?? "Unknown")")
            }
        })
    }
    
    func setupSDK(ethPrivKey: String, lightningClient: ILightningClient) throws {
        guard let filePath = Bundle.main.path(forResource: contractFileName, ofType: "json") else {
            throw NSError(domain: "FileNotFound", code: 404, userInfo: nil)
        }

        let jsonString = try String(contentsOfFile: filePath, encoding: .utf8)
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "InvalidData", code: 500, userInfo: nil)
        }
        
        guard let contracts = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
            throw NSError(domain: "InvalidJSON", code: 500, userInfo: nil)
        }
        
        let ethereum: SwapSdkConfig.Blockchains.Ethereum
        let network: SwapSdkConfig.Network
        
        switch config.network {
        case .playnet:
            network = SwapSdkConfig.Network(networkProtocol: .unencrypted, hostname: "localhost", port: 61280)

            ethereum = SwapSdkConfig.Blockchains.Ethereum(
                url: "ws://localhost:8545",
                chainId: "0x539",
                contracts: contracts,
                privKey: ethPrivKey
            )
        case .testnet:
            network = SwapSdkConfig.Network(networkProtocol: .encrypted, hostname: "node.playnet.portaldefi.zone", port: 1337)

            ethereum = SwapSdkConfig.Blockchains.Ethereum(
                url: "wss://sepolia.gateway.tenderly.co",
                chainId: "0xaa36a7",
                contracts: contracts,
                privKey: ethPrivKey
            )
        case .mainnet:
            fatalError("Not implemented")
        }
        
        let lightning = SwapSdkConfig.Blockchains.Lightning(client: lightningClient)
        let blockchains = SwapSdkConfig.Blockchains(ethereum: ethereum, lightning: lightning)
        
        let sdkConfig = SwapSdkConfig(
            id: UUID().uuidString,
            network: network,
            blockchains: blockchains
        )
        
        sdk = SDK.init(config: sdkConfig)
    }
    
    func submitLimitOrder() {
        guard let sdk = sdk else {
            return
        }
        
        swapState = .publishOrder
        
        sdk.start().then({ [unowned self] _ in
            let baseQuantity = Int(truncating: NSDecimalNumber(decimal: baseAmountPublisher.value * 100_000_000))
            let quoteQuantity = Int(truncating: NSDecimalNumber(decimal: quoteAmountPublisher.value * 1_000_000_000_000_000_000))
            
            let order = OrderRequest(
                baseAsset: "BTC",
                baseNetwork: "lightning.btc",
                baseQuantity: baseQuantity,
                quoteAsset: "ETH",
                quoteNetwork: "ethereum",
                quoteQuantity: quoteQuantity,
                side: orderSide.rawValue
            )
            
            sdk.submitLimitOrder(order).then { [unowned self] order in
                print("Order recieved: \(order)")
                self.order = order
                self.orders.append(order)
                self.swapState = .matchingOrder
            }.catch{ error in
                self.swapState = .swapError("submitting order error: \(error)")
            }
        }).catch({ [unowned self] error in
            self.swapState = .swapError("SDK start error: \(error)")
        })
    }
    
    func cancelOrder() {
        guard let order = order, let sdk = sdk else { return }
        
        sdk.cancelLimitOrder(order).then{ [unowned self] _ in
            self.swapState = .start
            
            orders.removeFirst()
            
            if sdk.isConnected {
                _ = sdk.stop()
            }
        }.catch{ [unowned self] error in
            self.swapState = .swapError("Cancel order error: \(error)")
        }
    }
    
    func clear() {
        swapState = .start
        baseAmount = String()
        quoteAmount = String()
        actionButtonEnabled = false
    }
}

