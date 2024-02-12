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
            rootView = AnyView(SendSelectAssetView())
        } else {
            rootView = AnyView(SetRecipientView(rootView: true))
        }
        
        navigationStack = NavigationStackView<AnyView>(
            configurator: SendViewNavigationConfig(),
            rootView: rootView
        )
    }
    
    var body: some View {
        navigationStack.zIndex(1)
    }
}

struct SendRootView_Previews: PreviewProvider {
    static var previews: some View {
        SendRootView(withAssetPicker: false)
    }
}
