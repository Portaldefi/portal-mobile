//
//  NoAccountRootView.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI

struct NoAccountRootView: View {
    private let navigationStack: NavigationStackView<NoAccountView>
    
    init() {
        let rootView = NoAccountView()
        
        navigationStack = NavigationStackView<NoAccountView>(
            configurator: NoAccountViewConfig(),
            rootView: rootView
        )
    }
    
    var body: some View {
        navigationStack.zIndex(1)
    }
}
