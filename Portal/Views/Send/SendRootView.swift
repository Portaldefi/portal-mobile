//
//  SendRootView.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI

struct SendRootView: View {
    private let navigationStack: NavigationStackView<SendView>
    
    init() {
        let rootView = SendView()
        
        navigationStack = NavigationStackView<SendView>(
            configurator: SendViewNavigationConfig(),
            rootView: rootView
        )
    }
    
    var body: some View {
        navigationStack.zIndex(1)
    }
}
