//
//  SendViewViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 25/8/22.
//

import Foundation
import Factory
import BitcoinAddressValidator
import Combine
import LocalAuthentication.LAError
import SwiftUI
import PortalUI

class SendViewViewModel: ObservableObject {
    enum SendStep {
        case recipient, amount, review, signing, sent
    }
    private let balanceAdapter: IBalanceAdapter
    var walletItems: [WalletItem] = []
    
    @Published var to = String()
    @Published var qrScannerOpened = false
    @Published var txSent = false
    @Published var selectedItem: WalletItem?
    @Published var qrCodeItem: QRCodeItem?
    @Published var goToReceive = false
    @Published var goToSend = false
    @Published var goToReview = false
    
    @Published var balanceString = String()
    @Published var valueString = String()
    @Published var fee: String?
    @Published var useAllFundsEnabled = true

    @Published private(set) var recipientAddressIsValid = true
    @Published private(set) var sendError: Error?
    @Published private(set) var step: SendStep = .recipient
    @Published var feesPickerSelection = 1
    
    @Published var exchanger = Exchanger(
        base: .bitcoin(),
        quote: .fiat(
            FiatCurrency(code: "USD", name: "United States Dollar", rate: 1)
        )
    )
    
    private var subscriptions = Set<AnyCancellable>()
    
    @ObservedObject private var account: AccountViewModel = Container.accountViewModel()
    @Injected(Container.marketData) private var marketData
    @Injected(Container.viewState) private var viewState
    @LazyInjected(Container.biometricAuthentification) private var biometrics
    
    var actionButtonEnabled: Bool {
        switch step {
        case .recipient:
            return !to.isEmpty
        case .amount:
            return exchanger.amountIsValid && Double(exchanger.cryptoAmount) ?? 0 > 0
        case .review:
            return true
        case .signing, .sent:
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
        }
    }
    
    init(balanceAdapter: IBalanceAdapter) {
        self.balanceAdapter = balanceAdapter
        
        self.balanceString = balanceAdapter.balance.formatted()
        let btcPriceInUsd = marketData.btcTicker?[.usd].price ?? 1
        self.valueString = (balanceAdapter.balance * btcPriceInUsd).double.usdFormatted()
        
        self.walletItems = account.items
        
        $selectedItem.sink { [unowned self] item in
            self.goToSend = item != nil
        }
        .store(in: &subscriptions)
        
        $qrCodeItem.sink { [unowned self] item in
            guard let item = item else { return }
            switch item.type {
            case .bip21(let address, let amount, _):
                self.selectedItem = walletItems.first
                self.to = address
                guard let amount = amount else { return }
                self.exchanger.cryptoAmount = amount
            default:
                break
            }

        }
        .store(in: &subscriptions)
        
        $to.sink { [unowned self] _ in
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
            guard let self = self else { return }
            let btcPriceInUsd = self.marketData.btcTicker?[.usd].price ?? 1
            self.valueString = (balanceAdapter.balance * btcPriceInUsd).double.usdFormatted()
        }
        .store(in: &subscriptions)
        
        exchanger.$cryptoAmount.sink { [weak self] _ in
            guard let self = self else { return }
            withAnimation {
                guard
                    let doubleValue = Double(self.exchanger.cryptoAmount),
                    doubleValue > 0,
                    self.exchanger.amountIsValid
                else {
                    self.fee = nil
                    self.useAllFundsEnabled = true
                    if self.viewState.showFeesPicker {
                        self.viewState.showFeesPicker = false
                    }
                    return
                }
                self.fee = "3"
                self.useAllFundsEnabled = !(self.exchanger.cryptoAmount == self.balanceString)
            }
        }
        .store(in: &subscriptions)
        
        exchanger.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        .store(in: &subscriptions)
    }
    
    func send() {
//        account.send(to: to, amount: exchanger.cryptoAmount, completion: { [weak self] error in
//            DispatchQueue.main.async {
//                self?.sendError = error
//                self?.txSent.toggle()
//            }
//        })
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
        
        switch step {
        case .recipient:
            shouldCloseSendFlow = true
        case .amount:
            step = .recipient
        case .review:
            step = .amount
        case .signing:
            step = .review
        case .sent:
            step = .recipient
        }
        
        return shouldCloseSendFlow
    }
    
    func toReview() {
        step = .review
    }
    
    func onActionButtonPressed() {
        switch step {
        case .recipient:
            if BitcoinAddressValidator.isValid(address: to) {
                step = .amount
            } else {
                recipientAddressIsValid = false
                sendError = SendFlowError.addressIsntValid
            }
        case .amount:
            step = .review
        case .review:
            step = .signing
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                self.step = .sent
            })
        case .signing:
            break
        case .sent:
            break
        }
    }
    
    func pasteFromClipboard() {
        let pasteboard = UIPasteboard.general
        if let pastboardString = pasteboard.string {
            to = pastboardString
        }
    }
    
    func openScanner() {
        qrScannerOpened = true
    }
    
    func useAllFunds() {
        exchanger.cryptoAmount = balanceString
        exchanger.cryptoAmount = balanceString
    }
}

extension SendViewViewModel {
    static var mocked: SendViewViewModel {
        SendViewViewModel(balanceAdapter: BalanceAdapterMocked())
    }
    
    static func config(coin: Coin) -> SendViewViewModel {
        let adapterManager: IAdapterManager = Container.adapterManager()
        let walletManager: IWalletManager = Container.walletManager()

        guard
            let wallet = walletManager.activeWallets.first(where: { $0.coin == coin }),
            let balanceAdapter = adapterManager.balanceAdapter(for: wallet)
        else {
            fatalError("coudn't fetch dependencies")
        }

        return SendViewViewModel(balanceAdapter: balanceAdapter)
    }
}
