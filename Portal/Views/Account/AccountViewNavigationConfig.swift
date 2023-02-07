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
        default:
            fatalError("unsupported navigation case")
        }
    }
}
