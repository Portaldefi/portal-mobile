//
//  MainView.swift
// Portal
//
//  Created by farid on 7/26/22.
//

import SwiftUI
import PortalUI
import Factory

struct Mainview: View {
    private let views: [AnyView]
    @ObservedObject private var viewState = Container.viewState()
    
    init() {
        UINavigationBar
            .appearance()
            .largeTitleTextAttributes = [
                .font : UIFont.monospacedSystemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white
            ]
        
        views = [
            AnyView(AccountRootView()),
            AnyView(ActivityView())
        ]
    }
        
    var TabBar: some View {
        HStack(spacing: 6.13) {
            Button {
                viewState.openTab(.wallet)
            } label: {
                if viewState.selectedTab == .wallet {
                    RadialGradient.main
                        .mask(
                            VStack(spacing: 4) {
                                Asset.homeIcon
                                Text("Wallet")
                                    .font(.Main.fixed(.bold, size: 14))
                            }
                        )
                } else {
                    VStack(spacing: 4) {
                        Asset.homeIcon
                        Text("Wallet")
                            .font(.Main.fixed(.bold, size: 14))
                    }
                    .foregroundColor(Color.gray)
                }
            }
            .frame(width: 65)
            
            Spacer()
            
            Button {
                viewState.openTab(.activity)
            } label: {
                if viewState.selectedTab == .activity {
                    RadialGradient.main
                        .mask(
                            VStack(spacing: 4) {
                                Asset.activityIcon
                                Text("Activity")
                                    .font(.Main.fixed(.bold, size: 14))
                            }
                        )
                } else {
                    VStack(spacing: 4) {
                        Asset.activityIcon
                        Text("Activity")
                            .font(.Main.fixed(.bold, size: 14))
                    }
                    .padding(6)
                    .foregroundColor(Color.gray)
                }
            }
            .frame(width: 85)
            .opacity(0.65)
            .disabled(true)
            
            Spacer()
            
            Button {
                viewState.showQRCodeScannerFromTabBar.toggle()
            } label: {
                Asset.scanQRIcon
            }
            .frame(width: 65)
        }
        .padding(.horizontal, 25.5)
        .frame(height: 65)
        .background(Palette.grayScale0A)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            views[viewState.selectedTab.rawValue]
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            TabBar
                .offset(y: viewState.hideTabBar ? 109 : 0)
                .zIndex(1)
        }
    }
}
