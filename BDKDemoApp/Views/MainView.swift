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
    @ObservedObject private var viewState = Container.viewState()
    
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
                viewState.openTab(.wallet)
            } label: {
                if viewState.selectedTab == .wallet {
                    gradiendColor
                        .mask(
                            VStack(spacing: 4) {
                                Asset.homeIcon
                                Text("Wallet")
                                    .font(.Main.fixed(.extraBold, size: 14))
                            }
                        )
                } else {
                    VStack(spacing: 4) {
                        Asset.homeIcon
                        Text("Wallet")
                            .font(.Main.fixed(.extraBold, size: 14))
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
                    gradiendColor
                        .mask(
                            VStack(spacing: 4) {
                                Asset.activityIcon
                                Text("Activity")
                                    .font(.Main.fixed(.extraBold, size: 14))
                            }
                        )
                } else {
                    VStack(spacing: 4) {
                        Asset.activityIcon
                        Text("Activity")
                            .font(.Main.fixed(.extraBold, size: 14))
                    }
                    .padding(6)
                    .foregroundColor(Color.gray)
                }
            }
            .frame(width: 85)
            
            Spacer()
            
            Button {
                viewState.showScanner.toggle()
            } label: {
                Asset.scanQRIcon
            }
            .frame(width: 65)
        }
        .padding(.horizontal, 25.5)
        .frame(height: 65)
        .background(Color(red: 10/255, green: 10/255, blue: 10/255))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            views[viewState.selectedTab.rawValue]
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            TabBar
        }
    }
}
