//
//  SettingsViewNavigationConfig.swift
//  Portal
//
//  Created by farid on 14.06.2023.
//

import SwiftUI

struct SettingsViewNavigationConfig: NavigationConfigurator {
    func configure(_ screen: Screen) -> ViewElement? {
        switch screen {
        case .securitySettings:
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(SecuritySettingsView(canGoBack: true))
            )
        case .setPinCode:
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(SetPincodeView())
            )
        default:
            fatalError("unsupported navigation case")
        }
    }
}


