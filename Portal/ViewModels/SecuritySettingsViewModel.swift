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
    @Injected(Container.viewState) var viewState

    @Published var pinCodeEnabled = false {
        didSet {
            settings.pincodeEnabled = pinCodeEnabled
        }
    }
    @Published var biometricEnabled = false {
        didSet {
            settings.biometricsEnabled = biometricEnabled
        }
    }
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        pinCodeEnabled = settings.pincodeEnabled
        biometricEnabled = settings.biometricsEnabled
    }
}
