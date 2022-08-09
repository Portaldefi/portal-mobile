//
//  HostingTabBarView.swift
//  BDKDemoApp
//
//  Created by farid on 7/26/22.
//

import SwiftUI

struct HostingTabBarView: View {
    private enum Tab: Hashable {
        case wallet
        case activity
        case defi
        case scan
    }
    
    @State private var selectedTab: Tab = .wallet
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AccountView(viewModel: AccountViewModel())
                .tag(0)
                .tabItem {
                    Text("Wallet")
                    Image(systemName: "house.fill")
                }
            Text("Activity")
                .tag(1)
                .tabItem {
                    Text("Activity")
                    Image(systemName: "magnifyingglass")
                }
//            Text("DeFi")
//                .tag(2)
//                .tabItem {
//                    Text("DeFi")
//                    Image(systemName: "person.crop.circle")
//                }
            Text("Scan")
                .tag(3)
                .tabItem {
                    Text("Scan")
                    Image(systemName: "gear")
                }
        }
    }
}

