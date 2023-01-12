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
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(CreateAccountView(words: words))
            )
        default:
            fatalError("unsupported navigation case")
        }
    }
}
