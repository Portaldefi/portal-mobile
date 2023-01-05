//
//  SendViewViewModel.swift
// Portal
//
//  Created by farid on 25/8/22.
//

import Foundation
import Factory
import Combine
import LocalAuthentication.LAError
import SwiftUI
import PortalUI
import BitcoinDevKit

class SendViewViewModel: ObservableObject {
    private var balanceAdapter: IBalanceAdapter?
    private var sendService: ISendAssetService?
    private var subscriptions = Set<AnyCancellable>()
    private var url: URL? = URL(string: "https://bitcoinfees.earn.com/api/v1/fees/recommended")
    private var urlSession: URLSession!
    private(set) var walletItems: [WalletItem] = []
    
    @Published var receiverAddress = String() {
        didSet {
            sendService?.receiverAddress.send(receiverAddress)
        }
    }
    
    @Published var txSent = false
    @Published var selectedItem: WalletItem?
    @Published var qrCodeItem: QRCodeItem?
    @Published var clipboardIsEmpty = false
    @Published var editingAmount = false
    @Published var fee: TxFees = .normal
    
    @Published private(set) var balanceString = String()
    @Published private(set) var valueString = String()
    @Published private(set) var useAllFundsEnabled = true
    @Published private(set) var recipientAddressIsValid = true
    @Published private(set) var sendError: Error?
    @Published private(set) var step: SendStep = .selectAsset
    @Published private(set) var recomendedFees: RecomendedFees?
    @Published private(set) var publishedTxId: String?
    @Published private(set) var unconfirmedTx: TransactionRecord?
    @Published private(set) var exchanger: Exchanger?
        
    @ObservedObject var viewState = Container.viewState()
    @ObservedObject private var account: AccountViewModel = Container.accountViewModel()

    @Injected(Container.marketData) private var marketData
    @LazyInjected(Container.biometricAuthentification) private var biometrics
    
    var actionButtonEnabled: Bool {
        guard let exchanger = exchanger else { return false }
        
        switch step {
        case .recipient:
            return !receiverAddress.isEmpty
        case .amount:
            return exchanger.amountIsValid && Double(exchanger.baseAmount.value.replacingOccurrences(of: ",", with: ".")) ?? 0 > 0
        case .review:
            return exchanger.amountIsValid
        case .signing, .sent:
            return false
        case .selectAsset:
            return false
        }
    }
    
    var actionButtonTitle: String {
        switch step {
        case .recipient, .amount:
            return "Continue"
        case .review:
            return "Send"
        case .signing, .sent:
            return String()
        case .selectAsset:
            return String()
        }
    }
    
    var title: String {
        switch step {
        case .recipient, .amount:
            return "Send"
        case .review:
            return "Review Transaction"
        case .signing:
            return "Singing..."
        case .sent:
            return "Signed!"
        case .selectAsset:
            return "Send"
        }
    }
    
    init() {
        subscribeForUpdates()
        updateRecomendedFees()
    }
    
    private func subscribeForUpdates() {
        $selectedItem.sink { [weak self] item in
            guard let self = self, let coin = item?.viewModel.coin else { return }

            self.updateAdapters(coin: coin)
            self.updateExchanger(coin: coin)
            
            withAnimation {
                self.step = .recipient
            }
        }
        .store(in: &subscriptions)
        
        $qrCodeItem.sink { [unowned self] item in
            guard let item = item else { return }
            switch item.type {
            case .bip21(let address, let amount, _):
                self.selectedItem = walletItems.first
                self.receiverAddress = address
                guard let amount = amount else {
                    step = .amount
                    return
                }
                self.exchanger?.baseAmount.value = amount
                self.step = .review
            case .eth(let address, let amount, _):
                self.selectedItem = walletItems.last
                self.receiverAddress = address
                guard let amount = amount else {
                    step = .amount
                    return
                }
                self.exchanger?.baseAmount.value = amount
                self.step = .review
            default:
                break
            }

        }
        .store(in: &subscriptions)
        
        $receiverAddress.sink { [unowned self] _ in
            guard sendError != nil, recipientAddressIsValid != true else { return }
            withAnimation {
                self.sendError = nil
                self.recipientAddressIsValid = true
            }
        }
        .store(in: &subscriptions)
        
        account.$items.sink { items in
            self.walletItems = items
        }
        .store(in: &subscriptions)
        
        marketData.onMarketDataUpdate.receive(on: RunLoop.main).sink { [weak self] _ in
            guard
                let self = self,
                let balanceAdapter = self.balanceAdapter,
                let coin = self.selectedItem?.viewModel.coin
            else { return }
            
            switch coin.type {
            case .bitcoin:
                let btcPriceInUsd = self.marketData.btcTicker?[.usd].price ?? 1
                self.valueString = (balanceAdapter.balance * btcPriceInUsd).double.usdFormatted()
            case .lightningBitcoin:
                fatalError("not implemented")
            case .ethereum, .erc20:
                let ethPriceInUsd: Decimal = 1200
                self.valueString = (balanceAdapter.balance * ethPriceInUsd).double.usdFormatted()
            }
        }
        .store(in: &subscriptions)
        
        $step
            .filter{ $0 == .sent }
            .flatMap{ _ in Just(true) }
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .assign(to: &$txSent)
    }
    
    private func updateExchanger(coin: Coin) {
        guard let balanceAdapter = self.balanceAdapter else { return }
        
        exchanger = Exchanger(
            base: coin,
            quote: .fiat(FiatCurrency(code: "USD", name: "United States Dollar", rate: 1)),
            balanceAdapter: balanceAdapter
        )
        
        guard let exchanger = exchanger else { return }
        
        exchanger.$baseAmount.sink { [weak self] amount in
            guard let self = self else { return }
            withAnimation {
                guard
                    let doubleValue = Double(amount.value),
                    doubleValue > 0,
                    exchanger.amountIsValid,
                    let decimal = Decimal(string: String(amount.value))
                else {
                    self.useAllFundsEnabled = true
                    return
                }
                self.useAllFundsEnabled = !(self.exchanger!.baseAmount.value == self.balanceString)
                self.sendService?.amount.send(decimal)
            }
        }
        .store(in: &subscriptions)
        
        exchanger.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        .store(in: &subscriptions)
    }
    
    private func updateAdapters(coin: Coin) {
        let adapterManager: IAdapterManager = Container.adapterManager()
        let walletManager: IWalletManager = Container.walletManager()

        guard
            let wallet = walletManager.activeWallets.first(where: { $0.coin == coin }),
            let adapter = adapterManager.adapter(for: wallet)
        else {
            fatalError("coudn't fetch dependencies")
        }

        switch coin.type {
        case .bitcoin:
            guard
                let balanceAdapter = adapter as? IBalanceAdapter,
                let sendAdapter = adapter as? ISendBitcoinAdapter
            else {
                fatalError("coudn't fetch dependencies")
            }
            self.balanceAdapter = balanceAdapter
            self.sendService = SendBTCService(balanceAdapter: balanceAdapter, sendAdapter: sendAdapter, feeRateProvider: MockeFeeRateProvider())
            
            self.balanceString = balanceAdapter.balance.formatted()
            let btcPriceInUsd = marketData.btcTicker?[.usd].price ?? 1
            self.valueString = (balanceAdapter.balance * btcPriceInUsd).double.usdFormatted()
        case .lightningBitcoin:
            fatalError("not implemented yet")
        case .ethereum, .erc20:
            guard
                let balanceAdapter = adapter as? IBalanceAdapter,
                let sendAdapter = adapter as? ISendEthereumAdapter
            else {
                fatalError("coudn't fetch dependencies")
            }
            
            let feeRateProvider = Container.feeRateProvider()
            let ethFeeRateProvider = EthereumFeeRateProvider(feeRateProvider: feeRateProvider)
            
            let ethManager = Container.ethereumKitManager()
            self.balanceAdapter = balanceAdapter
            self.sendService = SendETHService(coin: coin, balanceAdapter: balanceAdapter, sendAdapter: sendAdapter, feeRateProvider: ethFeeRateProvider, manager: ethManager)
            
            self.balanceString = balanceAdapter.balance.formatted()
            let btcPriceInUsd: Decimal = 1200
            self.valueString = (balanceAdapter.balance * btcPriceInUsd).double.usdFormatted()
        }
    }
    
    private func updateRecomendedFees() {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        
        self.urlSession = URLSession(configuration: config)
        
        guard let url = self.url else { return }
        
        urlSession.dataTaskPublisher(for: url)
            .tryMap { $0.data }
            .decode(type: RecomendedFees.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    print(error.localizedDescription)
                }
            } receiveValue: { [weak self] response in
                self?.recomendedFees = response
            }
            .store(in: &subscriptions)
    }
    
    func send(max: Bool) {
        if max {
//            sendAdapter.sendMax(to: to, fee: recomendedFees?.fee(fee)) { [weak self] txId, error in
//                guard let self = self else { return }
//
//                DispatchQueue.main.async {
//                    guard error == nil else {
//                        withAnimation {
//                            self.step = .review
//                            self.sendError = SendFlowError.error(error.debugDescription)
//                        }
//                        return
//                    }
//                    if let id = txId {
//                        self.publishedTxId = id
//
//                        let unconfirmedTx = BitcoinDevKit.TransactionDetails.unconfirmedSentTransaction(
//                            recipient: self.to,
//                            amount: self.exchanger.baseAmount.value,
//                            id: id
//                        )
//
////                        self.unconfirmedTx = TransactionRecord(transactionHash: unconfirmedTx.txid, transactionHashData: Data(), timestamp: unconfirmedTx.confirmationTime?.timestamp, isFailed: false, from: nil, to: nil, amount: unconfirmedTx.value, input: nil, blockHeight: unconfirmedTx.confirmationTime?.height, transactionIndex: nil, decoration: String())
//
//                        withAnimation {
//                            self.step = .sent
//                        }
//                    }
//                }
//            }
        } else {
//            sendAdapter.send(to: to, amount: exchanger.baseAmount.value, fee: recomendedFees?.fee(fee), completion: { [weak self] txId, error in
//                guard let self = self else { return }
//
//                DispatchQueue.main.async {
//                    guard error == nil else {
//                        withAnimation {
//                            self.step = .review
//                            self.sendError = SendFlowError.error(error.debugDescription)
//                        }
//                        return
//                    }
//                    if let id = txId {
//                        self.publishedTxId = id
//
//
//                        let unconfirmedTx = BitcoinDevKit.TransactionDetails.unconfirmedSentTransaction(
//                            recipient: self.to,
//                            amount: self.exchanger.baseAmount.value,
//                            id: id
//                        )
//
//                        withAnimation {
//                            self.step = .sent
//                        }
//                    }
//                }
//            })
        }
    }
    
    func authenticateUser(_ completion: @escaping (Bool) -> ()) {
        biometrics.authenticateUser { success, error in
            guard let error = error else {
                return completion(success)
            }

            switch error {
            case LAError.appCancel:
                // The app canceled authentication by
                // invalidating the LAContext
                completion(success)
            case LAError.authenticationFailed:
                // The user did not provide
                // valid credentials
                completion(success)
            case LAError.invalidContext:
                // The LAContext was invalid
                completion(success)
            case LAError.notInteractive:
                // Interaction was not allowed so the
                // authentication failed
                completion(success)
            case LAError.passcodeNotSet:
                // The user has not set a passcode
                // on this device
                completion(success)
            case LAError.systemCancel:
                // The system canceled authentication,
                // for example to show another app
                completion(success)
            case LAError.userCancel:
                // The user canceled the
                // authentication dialog
                completion(false)
            case LAError.userFallback:
                // The user selected to use a fallback
                // authentication method
                completion(success)
            case LAError.biometryLockout:
                // Too many failed attempts locked
                // biometric authentication
                completion(success)
            case LAError.biometryNotAvailable:
                // The user's device does not support
                // biometric authentication
                completion(true)
            case LAError.biometryNotEnrolled:
                // The user has not configured
                // biometric authentication
                completion(true)
            default:
                completion(success)
            }
        }
    }
    
    func goBack() -> Bool {
        var shouldCloseSendFlow = false
        sendError = nil
        
        switch step {
        case .recipient:
            selectedItem = nil
            step = .selectAsset
        case .amount:
            step = .recipient
        case .review:
            if viewState.showQRCodeScannerFromTabBar {
                shouldCloseSendFlow = true
            } else {
                step = .amount
            }
        case .signing:
            step = .review
        case .sent:
            step = .recipient
        case .selectAsset:
            shouldCloseSendFlow = true
        }
        
        return shouldCloseSendFlow
    }
    
    func toReview() {
        step = .review
    }
    
    func onActionButtonPressed() {
        sendError = nil
        
        switch step {
        case .recipient:
            do {
                try sendService?.validateAddress()
                step = .amount
            } catch {
                print("validation error: \(error)")
                recipientAddressIsValid = false
                sendError = SendFlowError.addressIsntValid
            }
        case .amount:
            step = .review
        case .review:
            biometrics.authenticateUser { [weak self] success, error in
                guard let self = self else { return }
                
                if let error = error {
                    DispatchQueue.main.sync {
                        withAnimation {
                            self.sendError = SendFlowError.error(error.errorUserInfo.description)
                        }
                    }
                }
                
                guard success else { return }
                    
                DispatchQueue.main.sync {
                    withAnimation {
                        self.step = .signing
                    }
                }
                
                self.send(max: !self.useAllFundsEnabled)
            }
        case .signing:
            break
        case .sent:
            break
        case .selectAsset:
            break
        }
    }
    
    func pasteFromClipboard() {
        let pasteboard = UIPasteboard.general
        if let pastboardString = pasteboard.string {
            receiverAddress = pastboardString
        } else {
            clipboardIsEmpty.toggle()
        }
    }
    
    func openScanner() {
        viewState.showInContextScanner = true
    }
    
    func useAllFunds() {
        exchanger?.baseAmount.value = balanceString
        exchanger?.baseAmount.value = balanceString
    }
}

extension SendViewViewModel {
    struct RecomendedFees: Codable {
        let fastestFee: Int
        let halfHourFee: Int
        let hourFee: Int
        
        func fee(_ state: TxFees) -> Int {
            switch state {
            case .normal:
                return halfHourFee
            case .fast:
                return fastestFee
            case .slow:
                return hourFee
            case .custom:
                fatalError("custom fees not implemented")
            }
        }
    }
    
    enum SendStep {
        case selectAsset, recipient, amount, review, signing, sent
    }
    
    enum TxFees {
        case fast, normal, slow, custom
        
        var description: String {
            switch self {
            case .fast:
                return "Fast ~ 10 mins"
            case .normal:
                return "Normal ~ 30 mins"
            case .slow:
                return "Slow ~ 60 mins"
            case .custom:
                return "Not implemented"
            }
        }
    }
    
    static var mocked: SendViewViewModel {
        let vm = SendViewViewModel(/*coin: .bitcoin(), balanceAdapter: BalanceAdapterMocked(), sendService: SendAssetMockedService()*/)
        vm.walletItems = [WalletItem.mockedBtc]
        vm.selectedItem = WalletItem.mockedBtc
        vm.unconfirmedTx = TransactionRecord(transaction: TransactionDetails.mockedConfirmed)
        vm.receiverAddress = "tb1q3ds30e5p59x9ryee4e2kxz9vxg5ur0tjsv0ug3"
        vm.balanceString = "0.000124"
        vm.valueString = "12.93"
        vm.exchanger?.baseAmount.value = "0.0000432"
        return vm
    }
}
