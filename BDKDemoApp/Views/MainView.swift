//
//  MainView.swift
//  BDKDemoApp
//
//  Created by farid on 7/26/22.
//

import SwiftUI
import PortalUI
import Factory

struct Mainview: View {
    private let views: [AnyView]
    @State private var selectedTab: Int = 0
    @Injected(Container.viewState) private var viewState
    
    init() {
        views = [
            AnyView(AccountView()),
            AnyView(ActivityView())
        ]
    }
    
    private var gradiendColor: RadialGradient {
        RadialGradient(
            colors: [
                Color(red: 116/255, green: 138/255, blue: 254/255),
                Color(red: 166/255, green: 78/255, blue: 255/255)
            ],
            center: .bottomTrailing,
            startRadius: 125,
            endRadius: 845
        )
    }
    
    var TabBar: some View {
        HStack(spacing: 6.13) {
            Button {
                selectedTab = 0
            } label: {
                VStack(spacing: 4) {
                    Asset.homeIcon
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
                    Asset.activityIcon
                    Text("Activity")
                        .font(.system(size: 14, design: .rounded))
                        .fontWeight(.bold)
                }
            }
            
            Spacer()
            
            Button {
                viewState.showScanner.toggle()
            } label: {
                Asset.scanQRIcon
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
            TabBar
        }
    }
}
