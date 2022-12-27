//
//  ReceiveRootView.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI

struct ReceiveRootView: View {
    private let navigationStack: NavigationStackView<ReceiveView>
    
    init(viewModel: ReceiveViewModel) {
        let rootView = ReceiveView(viewModel: viewModel)
        let navigationConfigurator = ReceiveViewNavigationConfig()
        
        navigationStack = NavigationStackView<ReceiveView>(
            configurator: navigationConfigurator,
            rootView: rootView
        )
    }
    
    var body: some View {
        navigationStack.zIndex(1)
    }
}
