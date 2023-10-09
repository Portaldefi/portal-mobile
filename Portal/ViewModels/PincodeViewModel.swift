//
//  PincodeViewModel.swift
//  Portal
//
//  Created by farid on 27.06.2023.
//

import SwiftUI
import Combine
import Factory
import LocalAuthentication

class PincodeViewModel: ObservableObject {
    enum PinState {
        case enter, notMatched
    }
    
    private let pinLength = 4
    
    private var transaction: Transaction = {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        return transaction
    }()
    
    @Published private(set) var state: PinState = .enter
    @Published private(set) var pin = String()
    @Published var requiredBiometrics = false
            
    @Injected(Container.secureStorage) var storage
    @Injected(Container.viewState) var viewState
    @Injected(Container.settings) var settings
    @LazyInjected(Container.biometricAuthentification) private var biometrics
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        print("Pincode vm init")
        
        $pin.dropFirst().filter{ $0.count == self.pinLength }.delay(for: 0.2, scheduler: RunLoop.main).sink { [unowned self] pin in
            withAnimation {
                guard let securedPin = storage.string(for: "PIN"), pin == securedPin else {
                    state = .notMatched
                    self.pin.removeAll()
                    return
                }
                unlock()
            }
        }
        .store(in: &subscriptions)
        
        $state.delay(for: 0.8, scheduler: RunLoop.main).sink { [unowned self] state in
            withAnimation {
                if state == .notMatched {
                    self.state = .enter
                }
            }
        }
        .store(in: &subscriptions)
        
        settings.biometricsEnabled.receive(on: RunLoop.main).sink { [unowned self] enabled in
            self.requiredBiometrics = enabled
            
            if self.viewState.sceneState == .active || self.viewState.sceneState == .background && enabled && self.settings.biometricsEnabled.value && self.viewState.walletLocked {
                self.biometricAuth()
            }
        }
        .store(in: &subscriptions)
        
        viewState.onSceneStateChange.filter{ $0 == .active }.subscribe(on: RunLoop.main).sink { [weak self] _ in
            guard let self = self else { return }
            print(self.requiredBiometrics)
            guard self.requiredBiometrics && self.settings.biometricsEnabled.value && self.viewState.walletLocked else { return }

            self.biometricAuth()
        }
        .store(in: &subscriptions)
    }
    
    private func biometricAuth() {
        biometrics.authenticateUser { success, error in
            DispatchQueue.main.async {
                if success {
                    self.unlock()
                } else {
                    if let error = error {
                        switch error {
                        case LAError.appCancel:
                            // The app canceled authentication by
                            // invalidating the LAContext
                            print("The app canceled authentication by invalidating the LAContext")
                            self.requiredBiometrics = false
                        case LAError.authenticationFailed:
                            // The user did not provide
                            // valid credentials
                            print("The user did not provide valid credentials")
                        case LAError.invalidContext:
                            // The LAContext was invalid
                            print("The LAContext was invalid")
                            self.requiredBiometrics = false
                        case LAError.notInteractive:
                            // Interaction was not allowed so the
                            // authentication failed
                            print("Interaction was not allowed so the authentication failed")
                        case LAError.passcodeNotSet:
                            // The user has not set a passcode
                            // on this device
                            print("The user has not set a passcode on this device")
                        case LAError.systemCancel:
                            // The system canceled authentication,
                            // for example to show another app
                            print("The system canceled authentication, for example to show another app")
                        case LAError.userCancel:
                            // The user canceled the
                            // authentication dialog
                            print("The user cancΩeled the authentication dialog")
                            self.requiredBiometrics = false
                        case LAError.userFallback:
                            // The user selected to use a fallback
                            // authentication method
                            print("The user selected to use a fallback authentication method")
                        case LAError.biometryLockout:
                            // Too many failed attempts locked
                            // biometric authentication
                            print("Too many failed attempts locked biometric authentication")
                            self.requiredBiometrics = false
                        case LAError.biometryNotAvailable:
                            // The user's device does not support
                            // biometric authentication
                            print("The user's device does not support biometric authentication")
                            self.settings.updateBiometricsSetting(enabled: false)
                            self.requiredBiometrics = false
                        case LAError.biometryNotEnrolled:
                            // The user has not configured
                            // biometric authentication
                            print("The user has not configured biometric authentication")
                            self.settings.updateBiometricsSetting(enabled: false)
                            self.requiredBiometrics = false
                        default:
                            print("Unknown authentification error")
                        }
                    }
                }
            }
        }
    }
    
    deinit {
        print("pincode vm deinit")
    }
        
    func add(digit: Int) {
        guard pin.count < pinLength else { return }

        withAnimation(.easeInOut(duration: 0.1)) {
            pin.append(String(digit))
        }
    }
    
    func removeLast() {
        withAnimation(.easeInOut(duration: 0.1)) {
            if !pin.isEmpty {
                pin.removeLast()
            }
        }
    }
    
    private func clear() {
        cancelSubscriptions()
    }
    
    private func unlock() {
        viewState.walletLocked = false
        clear()
    }
    
    func cancelSubscriptions() {
        subscriptions.forEach { $0.cancel() }
        subscriptions.removeAll()
    }
}
