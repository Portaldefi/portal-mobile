//
//  MainView.swift
//  BDKDemoApp
//
//  Created by farid on 7/26/22.
//

import SwiftUI

struct Mainview: View {
    private let views: [AnyView]
    @State var selectedTab: Int = 0
    @EnvironmentObject var viewState: ViewState
    
    init() {
        views = [
            AnyView(AccountView(viewModel: AccountViewModel())),
            AnyView(ActivityView()),
            AnyView(Spacer())
        ]
    }
    
    var tabBar: some View {
        HStack(spacing: 6.13) {
            Button {
                selectedTab = 0
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "house.fill")
                    Text("Wallet")
                        .font(.system(size: 14, design: .rounded))
                        .fontWeight(.bold)
                }
            }
            
            Spacer()
            
            Button {
                selectedTab = 1
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                    Text("Activity")
                        .font(.system(size: 14, design: .rounded))
                        .fontWeight(.bold)
                }
            }
            
            Spacer()
            
            Button {
                viewState.showScanner.toggle()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "target")
                    Text("Scan")
                        .font(.system(size: 14, design: .rounded))
                        .fontWeight(.bold)
                }
            }
        }
        .padding(.horizontal, 25.5)
        .frame(height: 65)
        .background(Color(red: 10/255, green: 10/255, blue: 10/255))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            views[selectedTab]
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            tabBar
        }
    }
}
