//
//  ReceiveRootView.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI

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
