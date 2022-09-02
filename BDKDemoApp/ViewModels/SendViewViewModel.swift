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

class SendViewViewModel: ObservableObject {
    var walletItems: [WalletItem] = []
    
    @Published var to = String()
    @Published var amount = String()
    @Published var qrScannerOpened = false
    @Published var showSuccessAlet = false
    @Published var showErrorAlert = false
    @Published var selectedItem: WalletItem?
    @Published var qrCodeItem: QRCodeItem?
    @Published var goToSend = false
    @Published var goToReview = false
    
    @Published private(set) var sendError: Error?
    
    private var subscriptions = Set<AnyCancellable>()
    
    @Injected(Container.accountViewModel) private var account
    @LazyInjected(Container.biometricAuthentification) private var biometrics
    
    var sendButtonEnabled: Bool {
        BitcoinAddressValidator.isValid(address: to) && (Double(amount) ?? 0) > 0
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
                self.amount = amount
            default:
                break
            }

        }
        .store(in: &subscriptions)
    }
    
    func send() {
        account.send(to: to, amount: amount, completion: { [weak self] error in
            guard let error = error else {
                self?.showSuccessAlet.toggle()
                return
            }
            self?.sendError = error
            self?.showErrorAlert.toggle()
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
}
