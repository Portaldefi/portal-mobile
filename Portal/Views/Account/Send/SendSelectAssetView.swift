//
//  SelectAssetView.swift
// Portal
//
//  Created by farid on 7/25/22.
//

import SwiftUI
import Combine
import PortalUI
import Factory

struct SendSelectAssetView: View {
    private var viewState: ViewState = Container.viewState()
    @Environment(\.presentationMode) private var presentationMode
    @Environment(NavigationStack.self) var navigation: NavigationStack
    @Environment(SendViewViewModel.self) var viewModel: SendViewViewModel
    @State private var notEnoughFunds = false
    @State private var notEnoughFundsMessage = String()
            
    var body: some View {
        let _ = Self._printChanges()

        VStack(spacing: 0) {
            ZStack {
                HStack {
                    PButton(config: .onlyIcon(Asset.xIcon), style: .free, size: .medium, enabled: true) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(width: 20)
                    
                    Spacer()
                }
                
                Text("Send")
                    .frame(width: 300, height: 62)
                    .font(.Main.fixed(.monoBold, size: 16))
            }
            .padding(.horizontal, 10)
            
            if !viewState.isReachable {
                NoInternetConnectionView()
                    .padding(.horizontal, -8)
                    .padding(.bottom, 6)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Asset")
                    .font(.Main.fixed(.bold, size: 24))
                    .foregroundColor(Palette.grayScaleCA)
                    .padding(.horizontal, 8)
                
                ScrollView {
                    VStack {
                        VStack(spacing: 0) {
                            ForEach(viewModel.walletItems) { item in
                                ZStack(alignment: .trailing) {
                                    WalletItemView(viewModel: item.viewModel)
                                        .padding(.leading, 16)
                                        .padding(.trailing, 22)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            if item.coin == .lightningBitcoin(), !viewModel.hasUsableChannels {
                                                if viewModel.hasChannelBalance {
                                                    
                                                } else {
                                                    
                                                }
                                            } else {
                                                guard item.viewModel.balance > 0 else {
                                                    notEnoughFundsMessage = "\(item.viewModel.coin.code) on \(item.viewModel.coin.description)"
                                                    return notEnoughFunds.toggle()
                                                }
                                                viewModel.coin = item.viewModel.coin
                                                navigation.push(.sendSetRecipient(viewModel: viewModel))
                                            }
                                        }
                                    Asset.chevronRightIcon
                                        .foregroundColor(Palette.grayScale4A)
                                }
                                
                                Divider()
                                    .frame(height: 1)
                                    .overlay(Palette.grayScale2A)
                            }
                        }
                    }
                    .disabled(!viewState.isReachable)
                    .opacity(viewState.isReachable ? 1 : 0.5)
                }
                .frame(height: CGFloat(viewModel.walletItems.count) * 72)
            }
        }
        .padding(.horizontal, 8)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .alert(isPresented: $notEnoughFunds) {
            Alert(title: Text("Not Enough Funds"),
                  message: Text("Your wallet doesn’t have \(notEnoughFundsMessage) to start this transfer."),
                  dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct SendFromView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.walletManager.register { WalletManager.mocked }
        let _ = Container.adapterManager.register { AdapterManager.mocked }
        let _ = Container.viewState.register { ViewState.mocked(hasConnection: true) }
        
        SendSelectAssetView().environment(SendViewViewModel.mocked)
    }
}

struct SendFromView_No_Connection: PreviewProvider {
    static var previews: some View {
        let _ = Container.walletManager.register { WalletManager.mocked }
        let _ = Container.adapterManager.register { AdapterManager.mocked }
        let _ = Container.viewState.register { ViewState.mocked(hasConnection: false) }
        
        SendSelectAssetView().environment(SendViewViewModel.mocked)
    }
}
