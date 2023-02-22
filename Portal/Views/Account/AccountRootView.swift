//
//  AccountRootView.swift
//  Portal
//
//  Created by farid on 12/13/22.
//

import SwiftUI

struct AccountRootView: View {
    private let navigationStack: NavigationStackView<AccountView>
    
    init() {
        let rootView = AccountView()
        let navigationConfigurator = AccountViewNavigationConfig()
        
        navigationStack = NavigationStackView<AccountView>(
            configurator: navigationConfigurator,
            rootView: rootView
        )
    }
    
    var body: some View {
        navigationStack.zIndex(1)
    }
}

import Factory

struct AccountRootView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.walletManager.register { WalletManager.mocked }
        let _ = Container.adapterManager.register { AdapterManager.mocked }
        
        AccountRootView()
    }
}

