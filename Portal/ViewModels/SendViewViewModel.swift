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

class SendViewViewModel: ObservableObject {
    private var sendService: ISendAssetService?
    private var subscriptions = Set<AnyCancellable>()
    private(set) var walletItems: [WalletItem] = []
    
    @Published var receiverAddress = String()
    @Published var txSent = false
    @Published var selectedItem: WalletItem?
    @Published var qrCodeItem: QRCodeItem?
    @Published var clipboardIsEmpty = false
    @Published var editingAmount = false
    @Published var feeRate: TxFees = .normal
    @Published var amountIsValid: Bool = true
    
    @Published private(set) var balanceString = String()
    @Published private(set) var valueString = String()
    @Published private(set) var useAllFundsEnabled = true
    @Published private(set) var recipientAddressIsValid = true
    @Published private(set) var sendError: Error?
    @Published private(set) var step: SendStep = .selectAsset
    @Published private(set) var publishedTxId: String?
    @Published private(set) var unconfirmedTx: TransactionRecord?
    @Published private(set) var exchanger: Exchanger?
        
    @ObservedObject var viewState = Container.viewState()
    @ObservedObject private var account: AccountViewModel = Container.accountViewModel()
    @Published var recomendedFees: RecomendedFees?

    @Injected(Container.marketData) private var marketData
    @LazyInjected(Container.biometricAuthentification) private var biometrics
        
    var fee: String {
        guard let coin = selectedItem?.viewModel.coin, let recomendedFees = recomendedFees, let sendService = sendService else { return String() }
        switch coin.type {
        case .bitcoin, .lightningBitcoin:
            return ((sendService.fee.double)/100_000_000).formattedString(.btc, decimals: 8)
        case .ethereum, .erc20:
            return recomendedFees.fee(feeRate).double.formattedString(.btc, decimals: 8)
        }
    }
    
    var actionButtonEnabled: Bool {
        guard let exchanger = exchanger else { return false }
        
        switch step {
        case .recipient:
            return !receiverAddress.isEmpty
        case .amount:
            return amountIsValid && Decimal(string: exchanger.baseAmount.value.replacingOccurrences(of: ",", with: ".")) ?? 0 > 0
        case .review:
            return amountIsValid
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
    
    var showFees: Bool {
        guard
            let exchanger = exchanger,
            amountIsValid,
            let amount = Decimal(string: exchanger.baseAmount.value.replacingOccurrences(of: ",", with: "."))
        else {
            return false
        }
        print("amount = \(amount)")
        return amount > 0
    }
    
    init() {
        subscribeForUpdates()
    }
    
    private func subscribeForUpdates() {
        $selectedItem
            .sink { [weak self] item in
                guard let self = self, let coin = item?.viewModel.coin else { return }
                
                self.updateAdapters(coin: coin)
                self.updateExchanger(coin: coin)
                
                withAnimation {
                    self.step = .recipient
                }
            }
            .store(in: &subscriptions)
        
        $qrCodeItem
            .sink { [unowned self] item in
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
        
        $receiverAddress
            .sink { [unowned self] address in
                self.sendService?.receiverAddress.send(address)
                guard sendError != nil, recipientAddressIsValid != true else { return }
                withAnimation {
                    self.sendError = nil
                    self.recipientAddressIsValid = true
                }
            }
            .store(in: &subscriptions)
        
        account
            .$items
            .sink { items in
                self.walletItems = items
            }
            .store(in: &subscriptions)
        
        marketData
            .onMarketDataUpdate
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self, let sendService = self.sendService, let coin = self.selectedItem?.viewModel.coin else { return }
                
                switch coin.type {
                case .bitcoin:
                    let btcPriceInUsd = self.marketData.btcTicker?[.usd].price ?? 1
                    self.valueString = (sendService.balance * btcPriceInUsd).double.usdFormatted()
                case .lightningBitcoin:
                    fatalError("not implemented")
                case .ethereum, .erc20:
                    let ethPriceInUsd: Decimal = 1200
                    self.valueString = (sendService.balance * ethPriceInUsd).double.usdFormatted()
                }
            }
            .store(in: &subscriptions)
        
        $step
            .filter{ $0 == .sent }
            .flatMap{ _ in Just(true) }
            .delay(for: .seconds(1), scheduler: RunLoop.main)
            .assign(to: &$txSent)
        
        $feeRate
            .sink { [unowned self] rate in
                sendService?.feeRateType.send(rate)
            }
            .store(in: &subscriptions)
    }
    
    private func updateExchanger(coin: Coin) {
        exchanger = Exchanger(
            base: coin,
            quote: .fiat(FiatCurrency(code: "USD", name: "United States Dollar", rate: 1))
        )
        
        guard let exchanger = exchanger, let sendService = self.sendService else { return }
        
        exchanger.baseAmount.$value.sink { [weak self] amount in
            guard let self = self, let decimalAmount = Decimal(string: amount.replacingOccurrences(of: ",", with: ".")) else { return }
                        
            withAnimation(.spring(response: 0.45, dampingFraction: 0.65, blendDuration: 0)) {
                self.amountIsValid = decimalAmount <= sendService.spendable
            }
            
            withAnimation {
                guard
                    self.amountIsValid, decimalAmount > 0
                else {
                    self.useAllFundsEnabled = true
                    return
                }
                self.useAllFundsEnabled = !(decimalAmount == sendService.spendable)
                sendService.amount.send(decimalAmount)
            }
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
            guard let sendAdapter = adapter as? ISendBitcoinAdapter else {
                fatalError("coudn't fetch dependencies")
            }
            
            sendService = SendBTCService(sendAdapter: sendAdapter)
            
            if let service = sendService {
                balanceString = service.balance.formatted()
                let btcPriceInUsd = marketData.btcTicker?[.usd].price ?? 1
                valueString = (service.balance * btcPriceInUsd).double.usdFormatted()
            }
        case .lightningBitcoin:
            fatalError("not implemented yet")
        case .ethereum, .erc20:
            guard let sendAdapter = adapter as? ISendEthereumAdapter else {
                fatalError("coudn't fetch dependencies")
            }
            
            let feeRateProvider = Container.feeRateProvider()
            let ethFeeRateProvider = EthereumFeeRateProvider(feeRateProvider: feeRateProvider)
            
            let ethManager = Container.ethereumKitManager()
            sendService = SendETHService(coin: coin, sendAdapter: sendAdapter, feeRateProvider: ethFeeRateProvider, manager: ethManager)
            
            if let service = sendService {
                balanceString = service.balance.formatted()
                let ethPriceInUsd: Decimal = 1200
                valueString = (service.balance * ethPriceInUsd).double.usdFormatted()
            }
        }
        
        sendService?.recomendedFees.sink { [weak self] fees in
            self?.recomendedFees = fees
        }
        .store(in: &subscriptions)
    }
    
    func send(max: Bool) {
        if max {
            sendService?
                .sendMax()
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    if case let .failure(error) = completion {
                        withAnimation {
                            self.step = .review
                            self.sendError = error
                        }
                    }
                }, receiveValue: { [weak self] txId in
                    guard let self = self, let service = self.sendService, let exchanger = self.exchanger else { return }

                    self.publishedTxId = txId
                    self.unconfirmedTx = service.unconfirmedTx(id: txId, amount: exchanger.baseAmount.value)
                    
                    withAnimation {
                        self.step = .sent
                    }
                })
                .store(in: &subscriptions)
        } else {
            sendService?
                .send()
                .receive(on: RunLoop.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    
                    if case let .failure(error) = completion {
                        withAnimation {
                            self.step = .review
                            self.sendError = error
                        }
                    }
                }, receiveValue: { [weak self] txId in
                    guard let self = self, let service = self.sendService, let exchanger = self.exchanger else { return }

                    self.publishedTxId = txId
                    self.unconfirmedTx = service.unconfirmedTx(id: txId, amount: exchanger.baseAmount.value)
                    
                    withAnimation {
                        self.step = .sent
                    }
                })
                .store(in: &subscriptions)
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
            receiverAddress = String()
            recipientAddressIsValid = true
            sendError = nil
            step = .selectAsset
        case .amount:
            exchanger?.baseAmount.value = String()
            useAllFundsEnabled = true
            sendError = nil
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
        guard let sendService = sendService else { return }
        let spendable = sendService.spendable.formatted()
        exchanger?.baseAmount.value = spendable
        useAllFundsEnabled = false
    }
}

extension SendViewViewModel {
    enum SendStep {
        case selectAsset, recipient, amount, review, signing, sent
    }
    
    static var mocked: SendViewViewModel {
        let vm = SendViewViewModel()
        vm.walletItems = [WalletItem.mockedBtc]
        vm.selectedItem = WalletItem.mockedBtc
        vm.receiverAddress = "tb1q3ds30e5p59x9ryee4e2kxz9vxg5ur0tjsv0ug3"
        vm.balanceString = "0.000124"
        vm.valueString = "12.93"
        vm.exchanger?.baseAmount.value = "0.0000432"
        return vm
    }
}
