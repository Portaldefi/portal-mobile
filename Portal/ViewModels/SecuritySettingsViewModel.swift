//
//  SecuritySettingsViewModel.swift
//  Portal
//
//  Created by farid on 27.06.2023.
//

import Combine
import Factory
import Foundation

class SecuritySettingsViewModel: ObservableObject {
    @Injected(Container.settings) var settings
    @Injected(Container.biometricAuthentification) var biometrics
    
    var biometricsEnrolledPublisher: AnyPublisher<Bool, Never> {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .map { [unowned self] _ in
                biometrics.isBiometricEnrolled()
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    @Published var pinCodeEnabled = false {
        didSet {
            settings.updatePinCodeSetting(enabled: pinCodeEnabled)
            guard !pinCodeEnabled && biometricEnabled else { return }
            biometricEnabled = false
        }
    }
    @Published var biometricEnabled = false {
        didSet {
            guard biometricEnabled != settings.biometricsEnabled.value else { return }
            
            if biometricEnabled {
                biometrics.authenticateUser { [unowned self] success, error in
                    if success {
                        settings.updateBiometricsSetting(enabled: success)
                    } else {
                        biometricEnabled = false
                    }
                }
            } else {
                guard settings.biometricsEnabled.value else { return }
                settings.updateBiometricsSetting(enabled: false)
            }
        }
    }
        
    init() {
        pinCodeEnabled = settings.pincodeEnabled.value
        biometricEnabled = settings.biometricsEnabled.value
    }
    
    deinit {
        print("SecuritySettingsViewModel DEINITED")
    }
}
