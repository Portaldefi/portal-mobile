//
//  AccountBackupNavigationConfig.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI

struct AccountBackupNavigationConfig: NavigationConfigurator {
    func configure(_ screen: Screen) -> ViewElement? {
        switch screen {
        case .recoveryPhrase(let viewModel):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(RecoveryPhraseView(viewModel: viewModel))
            )
        case .recoveryPhraseTest(let viewModel):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(RecoveryPhraseTestView(viewModel: viewModel))
            )
        case .recoveryWarning(let viewModel):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(ResponsibleWarningView(viewModel: viewModel))
            )
        default:
            fatalError("unsupported navigation case")
        }
    }
}
