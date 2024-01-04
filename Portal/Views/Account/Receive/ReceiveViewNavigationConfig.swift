//
//  ReceiveViewNavigationConfig.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI

struct CreateChannelViewNavigationConfig: NavigationConfigurator {
    func configure(_ screen: Screen) -> ViewElement? {
        switch screen {
        case .createChannelView(let peer):
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(CreateChannelView(peer: peer))
            )
        case .awaitsFundingChannelView:
            return ViewElement(
                id: screen.id,
                wrappedElement: AnyView(AwaitsFundingChannelView())
            )
        default:
            fatalError("unsupported navigation case")
        }
    }
}

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
