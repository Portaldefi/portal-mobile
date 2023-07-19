//
//  SecuritySettingsViewModel.swift
//  Portal
//
//  Created by farid on 27.06.2023.
//

import Combine
import Factory

class SecuritySettingsViewModel: ObservableObject {
    @Injected(Container.settings) var settings
    @Injected(Container.biometricAuthentification) var biometrics

    @Published var pinCodeEnabled = false {
        didSet {
            settings.updatePinCodeSetting(enabled: pinCodeEnabled)
        }
    }
    @Published var biometricEnabled = false {
        didSet {
            if biometricEnabled && !biometrics.permissionsGranted {
                biometrics.authenticate()
            }
            settings.updateBiometricsSetting(enabled: biometricEnabled)
        }
    }
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        pinCodeEnabled = settings.pincodeEnabled.value
        biometricEnabled = settings.biometricsEnabled.value
    }
}
