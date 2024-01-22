//
//  CreateChannelRootView.swift
//  Portal
//
//  Created by farid on 18.01.2024.
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

#Preview {
    CreateChannelRootView(channelIsFunded: false)
}
