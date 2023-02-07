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
        case .sendSelectAsset(let viewModel):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(SelectAssetView(viewModel: viewModel))
            )
        case .sendSetRecipient(let viewModel):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(SetRecipientView(viewModel: viewModel, dismissable: false))
            )
        case .sendSetAmount(let viewModel):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(SetAmountView(viewModel: viewModel))
            )
        case .sendReviewTxView(let viewModel):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(ReviewTransactionView(viewModel: viewModel))
            )
        default:
            fatalError("unsupported navigation case")
        }
    }
}
