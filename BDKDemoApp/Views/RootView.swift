//
//  RootView.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = RootViewViewModel.config()
    
    var body: some View {
        switch viewModel.state {
        case .empty:
            NoAccountView()
        case .account:
            HostingTabBarView()
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
