//
//  SendViewNavigationConfig.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI

struct SendViewNavigationConfig: NavigationConfigurator {
    func configure(_ screen: Screen) -> ViewElement? {
        switch screen {
        case .transactionDetails(let coin, let tx):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(TransactionDetailsView(coin: coin, tx: tx))
            )
        default:
            fatalError("unsupported navigation case")
        }
    }
}
