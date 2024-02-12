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
                wrappedElement: AnyView(TransactionView(coin: coin, tx: tx))
            )
        case .sendSelectAsset(let viewModel):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(SendSelectAssetView().environment(viewModel))
            )
        case .sendSetRecipient(let viewModel):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(SetRecipientView(rootView: false).environment(viewModel))
            )
        case .sendSetAmount(let viewModel):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(SetAmountView().environment(viewModel))
            )
        case .sendReviewTxView(let viewModel):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(ReviewTransactionView().environment(viewModel))
            )
        default:
            fatalError("unsupported navigation case")
        }
    }
}
