//
//  AccountViewNavigationConfig.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI

struct AccountViewNavigationConfig: NavigationConfigurator {
    func configure(_ screen: Screen) -> ViewElement? {
        switch screen {
        case .assetDetails(let item):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(AssetDetailsView(item: item))
            )
        case .send:
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(SendView())
            )
        case .receive(let item):
            let receiveViewModel = ReceiveViewModel.config(items: [item], selectedItem: nil)
            
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(ReceiveView(viewModel: receiveViewModel))
            )
        default:
            fatalError("unsupported navigation case")
        }
    }
}
