//
//  RootView.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = RootViewViewModel.config()
    @StateObject private var accountViewModel = AccountViewModel()
    @StateObject private var viewState = ViewState()
    
    var body: some View {
        switch viewModel.state {
        case .empty:
            NoAccountView()
        case .account:
            Mainview()
                .environmentObject(viewState)
                .environmentObject(accountViewModel)
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
