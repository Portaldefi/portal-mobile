//
//  SendRootView.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI
import Factory

struct SendRootView: View {
    private let navigationStack: NavigationStackView<AnyView>
    
    init(withAssetPicker: Bool) {
        let rootView: AnyView
        
        if withAssetPicker {
            rootView = AnyView(SendSelectAssetView(viewModel: Container.sendViewModel()))
        } else {
            rootView = AnyView(SetRecipientView(viewModel: Container.sendViewModel(), rootView: true))
        }
        
        navigationStack = NavigationStackView<AnyView>(
            configurator: SendViewNavigationConfig(),
            rootView: rootView
        )
    }
    
    var body: some View {
        navigationStack.zIndex(1).navigationBarBackButtonHidden()
    }
}
