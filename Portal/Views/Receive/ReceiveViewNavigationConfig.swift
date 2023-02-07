//
//  ReceiveViewNavigationConfig.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI

struct ReceiveViewNavigationConfig: NavigationConfigurator {
    func configure(_ screen: Screen) -> ViewElement? {
        switch screen {
        case .receiveGenerateQRCode(let viewModel):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(QRCodeGeneratorView(rootView: false, viewModel: viewModel))
            )
        default:
            fatalError("unsupported navigation case")
        }
    }
}
