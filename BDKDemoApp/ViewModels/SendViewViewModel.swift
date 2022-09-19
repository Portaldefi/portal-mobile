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
        case recipient, amount, review, confirmation
    }
    var walletItems: [WalletItem] = []
    
    @Published var to = String()
    @Published var qrScannerOpened = false
    @Published var txSent = false
    @Published var selectedItem: WalletItem?
    @Published var qrCodeItem: QRCodeItem?
    @Published var goToReceive = false
    @Published var goToSend = false
    @Published var goToReview = false
    
    @Published private(set) var recipientAddressIsValid = true
    @Published private(set) var sendError: Error?
    @Published private(set) var step: SendStep = .recipient
    
    @ObservedObject var exchanger = Exchanger(
        coin: .bitcoin(),
        currency: .fiat(
            FiatCurrency(code: "USD", name: "United States Dollar", rate: 1)
        )
    )
    
    private var subscriptions = Set<AnyCancellable>()
    
    @ObservedObject private var account: AccountViewModel = Container.accountViewModel()
    @LazyInjected(Container.biometricAuthentification) private var biometrics
    
    var actionButtonEnabled: Bool {
        switch step {
        case .recipient:
            return !to.isEmpty
        case .amount:
            return exchanger.isValid && Double(exchanger.cryptoAmount) ?? 0 > 0
        case .review:
            return false
        case .confirmation:
            return false
        }
    }
    
    var actionButtonTitle: String {
        switch step {
        case .recipient, .amount:
            return "Continue"
        case .review:
            return "Send"
        case .confirmation:
            return "Done"
        }
    }
    
    var title: String {
        switch step {
        case .recipient, .amount:
            return "Send"
        case .review:
            return "Review Transaction"
        case .confirmation:
            return "Confirmation"
        }
    }
    
    init() {
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
        
        Publishers.CombineLatest(exchanger.$cryptoAmount, exchanger.$currencyAmount).sink { [unowned self] _ in
            objectWillChange.send()
        }
        .store(in: &subscriptions)
        
        account.$items.sink { items in
            self.walletItems = items
        }
        .store(in: &subscriptions)
        
        exchanger.$cryptoAmount.sink { newValue in
            withAnimation {
                guard !newValue.isEmpty, Double(newValue) ?? 0 > 0 else {
                    if self.exchanger.fee != String() {
                        self.exchanger.fee = String()
                    }
                    return
                }
                self.exchanger.fee = "0.000234"
            }
        }
        .store(in: &subscriptions)
    }
    
    func send() {
        account.send(to: to, amount: exchanger.cryptoAmount, completion: { [weak self] error in
            DispatchQueue.main.async {
                self?.sendError = error
                self?.txSent.toggle()
            }
        })
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
        case .confirmation:
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
            break
        case .confirmation:
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
}

extension SendViewViewModel {
    static var mocked: SendViewViewModel {
        SendViewViewModel()
    }
}
