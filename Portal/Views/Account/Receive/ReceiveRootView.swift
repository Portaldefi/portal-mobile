//
//  ReceiveRootView.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI

struct CreateChannelRootView: View {
    private let navigationStack: NavigationStackView<AnyView>
    
    init(channelIsFunded: Bool) {
        let rootView: AnyView
        
        if channelIsFunded {
            rootView = AnyView(AwaitsFundingChannelView())
        } else {
            rootView = AnyView(SelectPeerView())
        }
                
        let navigationConfigurator = CreateChannelViewNavigationConfig()
        
        navigationStack = NavigationStackView<AnyView>(
            configurator: navigationConfigurator,
            rootView: rootView
        )
    }

    var body: some View {
        navigationStack.zIndex(1)
    }
}

struct ReceiveRootView: View {
    private let navigationStack: NavigationStackView<AnyView>
    
    init(viewModel: ReceiveViewModel, withAssetPicker: Bool) {
        let rootView: AnyView
        
        if withAssetPicker {
            rootView = AnyView(ReceiveSelectAssetView(viewModel: viewModel))
        } else {
            rootView = AnyView(QRCodeGeneratorView(rootView: true, viewModel: viewModel))
        }
                
        let navigationConfigurator = ReceiveViewNavigationConfig()
        
        navigationStack = NavigationStackView<AnyView>(
            configurator: navigationConfigurator,
            rootView: rootView
        )
    }
    
    var body: some View {
        navigationStack.zIndex(1)
    }
}

import Factory

struct ReceiveRootView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.walletManager.register { WalletManager.mocked }
        let _ = Container.adapterManager.register { AdapterManager.mocked }
        
        ReceiveRootView(viewModel: ReceiveViewModel.mocked, withAssetPicker: true)
    }
}
