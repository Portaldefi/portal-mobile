//
//  ReceiveViewModel.swift
// Portal
//
//  Created by farid on 9/22/22.
//

import Foundation
import Factory
import Combine
import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeSharedItem: Identifiable {
    let id = UUID()
    let name: String
    let displayedItem: String
    let item: String
}

@Observable class ReceiveViewModel {
    enum RecieveStep {
        case selectAsset, generateQR
    }
        
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    public var editingAmount = false
    
    public var description = String() {
        didSet {
            description$.send(description)
        }
    }
    @ObservationIgnored private var description$ = CurrentValueSubject<String, Never>(String())

    public var editingDescription = false
    public var showConfirmationOnCopy = false
    public var showNetworkSelector = false
    public var showFullQRCodeString = false
    public var onAmountChange = false {
        didSet {
            onAmountChange$.send(onAmountChange)
        }
    }
    @ObservationIgnored private var onAmountChange$ = CurrentValueSubject<Bool, Never>(false)
    
    private(set) var qrCode: UIImage?
    private(set) var walletItems = [WalletItem]()
    
    public var sharedAddress: IdentifiableString?
    
    @ObservationIgnored public var selectedItem: WalletItem? {
        didSet {
            guard let item = selectedItem else { return }
            updateExchanger(coin: item.coin)
        }
    }
    @ObservationIgnored public var exchanger: Exchanger?
    @ObservationIgnored public var qrAddressType: BTCQRCodeAddressType = .lightning {
        didSet {
            qrAddressType$.send(qrAddressType)
        }
    }
    @ObservationIgnored private var qrAddressType$ = CurrentValueSubject<BTCQRCodeAddressType, Never>(.lightning)
    
    public var qrCodeString = String()
    public var sharedItems: [QRCodeSharedItem] = []
    public var sharedItem: QRCodeSharedItem?
    
    @ObservationIgnored private var marketData = Container.marketData()
    @ObservationIgnored private var settings = Container.settings()
    @ObservationIgnored private var lightningKit = Container.lightningKitManager()
    
    @ObservationIgnored private var subscriptions = Set<AnyCancellable>()
    
    var fiatCurrency: FiatCurrency {
        settings.fiatCurrency.value
    }
    
    var hasUsableChannels: Bool {
        !lightningKit.usableChannels.isEmpty
    }
    
    var hasChannelBalance: Bool {
        lightningKit.channelBalance > 0
    }
    
    init(items: [WalletItem], selectedItem: WalletItem?) {
        self.walletItems = items
        self.selectedItem = selectedItem
        
        guard let item = selectedItem else { return }
        updateExchanger(coin: item.coin)
    }
    
    private func updateExchanger(coin: Coin?) {
        subscriptions.removeAll()
        description = String()
        
        guard let coin = coin else {
            exchanger = nil
            return
        }
        
        let price: Decimal
        
        switch coin.type {
        case .bitcoin, .lightningBitcoin:
            price = marketData.lastSeenBtcPrice * fiatCurrency.rate
        case .ethereum:
            price = marketData.lastSeenEthPrice * fiatCurrency.rate
            qrAddressType = .onChain
        case .erc20(let address):
            if address == "0x326C977E6efc84E512bB9C30f76E30c160eD06FB" {
                price = marketData.lastSeenLinkPrice * fiatCurrency.rate
                qrAddressType = .onChain
            } else {
                price = 0
            }
        }
        
        exchanger = Exchanger(
            base: coin,
            quote: .fiat(fiatCurrency),
            price: price
        )
        
        guard let exchanger = exchanger else { return }
        
        Publishers.CombineLatest3(onAmountChange$, description$, qrAddressType$)
            .flatMap { _ in Just(()) }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self, let coin = selectedItem?.coin else { return }
                
                switch coin.type {
                case .bitcoin, .ethereum, .erc20:
                    let addressString = depositAdapter()?.receiveAddress ?? "Unknown address"
                    let displayedAddress = addressString.groupedByFour.uppercased()
                    self.sharedItems = [QRCodeSharedItem(name: "On Chain Address", displayedItem: displayedAddress, item: addressString)]
                    self.generateQRCode(coin: exchanger.base, code: addressString)
                case .lightningBitcoin:
                    Task {
                        let invoice = await self.lightningKit.createInvoice(amount: exchanger.baseAmountString, description: self.description)
                        
                        DispatchQueue.main.async {
                            self.generateQRCode(coin: exchanger.base, code: invoice ?? String())
                            self.sharedItems = [QRCodeSharedItem(name: "Lightning Invoice", displayedItem: invoice?.turnicated.uppercased() ?? String(), item: invoice ?? String())]
                        }
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    private func depositAdapter() -> IDepositAdapter? {
        guard let item = selectedItem else { return nil }
        
        switch item.coin.type {
        case .bitcoin, .ethereum, .erc20:
            let adapterManager: IAdapterManager = Container.adapterManager()
            let walletManager: IWalletManager = Container.walletManager()
                    
            guard
                let wallet = walletManager.activeWallets.first(where: { $0.coin == item.coin }),
                let depositAdapter = adapterManager.depositAdapter(for: wallet)
            else {
                return nil
            }
            return depositAdapter
        default:
            return nil
        }
    }
        
    private func generateQRCode(coin: Coin, code: String) {
        var qrCodeString: String
        
        switch coin.type {
        case .bitcoin:
            qrCodeString = "bitcoin:\(code)"
            
            if let components = pathComponents() {
                qrCodeString += components
            }
        case .lightningBitcoin:
            qrCodeString = "lightning:\(code)"
        case .ethereum:
            qrCodeString = "ethereum:\(code)"
            
            if let components = pathComponents() {
                qrCodeString += components
            }
        case .erc20:
            qrCodeString = "\(coin.name.lowercased()):\(code)"
            
            if let components = pathComponents() {
                qrCodeString += components
            }
        }
        
        self.qrCodeString = qrCodeString
        
        print("QR CODE STRING: \n\(qrCodeString)\n")
        
        let data = Data(qrCodeString.utf8)
        filter.setValue(data, forKey: "inputMessage")

        guard
            let outputImage = filter.outputImage,
            let cgimg = context.createCGImage(outputImage, from: outputImage.extent)
        else {
            return
        }
        
        qrCode = UIImage(cgImage: cgimg)
    }
    
    private func pathComponents() -> String? {
        guard let exchanger = exchanger else { return nil }

        var components = URLComponents()
        components.queryItems = []
        
        if exchanger.baseAmountDecimal > 0 {
            components.queryItems?.append(URLQueryItem(name: "amount", value: exchanger.baseAmountString))
        }

        if !description.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "message", value: description))
        }
                
        if let parameters = components.string, parameters != "?" {
            return parameters
        }
        
        return nil
    }
    
    func copyToClipboard() {
        if let item = sharedItem?.item {
            UIPasteboard.general.string = item
            showConfirmationOnCopy.toggle()
        }
    }
    
    func share() {
        guard let coin = selectedItem?.coin else { return }
        
        let description: String
        
        switch coin.type {
        case .bitcoin:
            description = "\n\nThis is a bitcoin network address. Only send BTC to this address. Do not send lightning network assets to his address."
            sharedAddress = IdentifiableString(text: qrCodeString + description)
        case .lightningBitcoin:
            description = "\n\nThis is a lightning invoice."
            sharedAddress = IdentifiableString(text: qrCodeString + description)
        case .ethereum, .erc20:
            description = "\n\nThis is an ethereum network address."
            sharedAddress = IdentifiableString(text: qrCodeString + description)
        }
    }
    
    var isIPod: Bool {
        return UIScreen.main.bounds.height == 568 && UIScreen.main.bounds.width == 320
    }
}

extension ReceiveViewModel {
    static func config(items: [WalletItem], selectedItem: WalletItem?) -> ReceiveViewModel {
        ReceiveViewModel(items: items, selectedItem: selectedItem)
    }
    
    static var mocked: ReceiveViewModel {
        ReceiveViewModel(items: [WalletItem.mockedBtc], selectedItem: WalletItem.mockedBtc)
    }
}
