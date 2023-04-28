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
        views = [
            AnyView(AccountRootView()),
            AnyView(SwapView()),
            AnyView(LightningStatstView())
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
                viewState.openTab(.swap)
            } label: {
                if viewState.selectedTab == .swap {
                    RadialGradient.main
                        .mask(
                            VStack(spacing: 4) {
                                Asset.swapIcon
                                Text("Swap")
                                    .font(.Main.fixed(.bold, size: 14))
                            }
                        )
                } else {
                    VStack(spacing: 4) {
                        Asset.swapIcon
                        Text("Swap")
                            .font(.Main.fixed(.bold, size: 14))
                    }
                    .foregroundColor(Color.gray)
                }
            }
            .frame(width: 85)
            
            Spacer()
                        
            Button {
                viewState.openTab(.lightning)
            } label: {
                if viewState.selectedTab == .lightning {
                    RadialGradient.main
                        .mask(
                            VStack(spacing: 4) {
                                Asset.lightningIcon
                                Text("Lightning")
                                    .font(.Main.fixed(.bold, size: 14))
                            }
                        )
                } else {
                    VStack(spacing: 4) {
                        Asset.lightningIcon
                        Text("Lightning")
                            .font(.Main.fixed(.bold, size: 14))
                    }
                    .padding(6)
                    .foregroundColor(Color.gray)
                }
            }
            .frame(width: 85)
            .disabled(false)
            
            Spacer()
            
            Button {
                viewState.showQRCodeScannerFromTabBar.toggle()
            } label: {
                Asset.scanQRIcon
            }
            .frame(width: 65)
        }
        .opacity(viewState.hideTabBar ? 0.25 : 1)
        .padding(.horizontal, 25.5)
        .frame(height: 65)
        .background(Palette.grayScale0A)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            views[viewState.selectedTab.rawValue]
            
            TabBar
                .offset(y: viewState.hideTabBar ? 109 : 0)
                .zIndex(1)
        }
    }
}

struct Mainview_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.walletManager.register { WalletManager.mocked }
        let _ = Container.adapterManager.register { AdapterManager.mocked }
        
        Mainview()
    }
}

