//
//  SettingsRootView.swift
//  Portal
//
//  Created by farid on 14.06.2023.
//

import SwiftUI

struct SettingsRootView: View {
    private let navigationStack: NavigationStackView<AnyView>
    
    init() {        
        let rootView = AnyView(SettingsView())
       
        let navigationConfigurator = SettingsViewNavigationConfig()
        
        navigationStack = NavigationStackView<AnyView>(
            configurator: navigationConfigurator,
            rootView: rootView
        )
    }
    
    var body: some View {
        navigationStack.zIndex(1)
    }
}

struct SettingsRootView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsRootView()
    }
}
