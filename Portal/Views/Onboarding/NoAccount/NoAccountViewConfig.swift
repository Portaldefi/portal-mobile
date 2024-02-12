//
//  NoAccountViewConfig.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI

struct NoAccountViewConfig: NavigationConfigurator {
    func configure(_ screen: Screen) -> ViewElement? {
        switch screen {
        case .createAccount:
//            let viewModel = CreateAccountViewModel()
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(CreateAccountView())
            )
        case .restoreAccount:
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(RestoreAccountView())
            )
        case .restoreConfirmation(let viewModel):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(ConfirmImportAccountView(viewModel: viewModel))
            )
        case .nameAccount(let words):
            let viewModel = CreateAccountViewModel(words: words)
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(SetSecuritySettingsView(viewModel: viewModel))
            )
        case .setSecuritySettings:
            let viewModel = CreateAccountViewModel()
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(SetSecuritySettingsView(viewModel: viewModel))
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
