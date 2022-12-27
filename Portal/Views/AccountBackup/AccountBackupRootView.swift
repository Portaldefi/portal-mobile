//
//  AccountBackupRootView.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI

struct AccountBackupRootView: View {
    private let navigationStack: NavigationStackView<BackUpDetailsView>
    
    init() {
        let rootView = BackUpDetailsView()
        let navigationConfigurator = AccountBackupNavigationConfig()
        
        navigationStack = NavigationStackView<BackUpDetailsView>(
            configurator: navigationConfigurator,
            rootView: rootView
        )
    }
    
    var body: some View {
        navigationStack.zIndex(1)
    }
}
