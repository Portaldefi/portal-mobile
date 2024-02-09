//
//  AccountView.swift
// Portal
//
//  Created by farid on 7/20/22.
//

import SwiftUI
import PortalUI
import Factory

struct AccountView: View {
    @Environment(NavigationStack.self) var navigation: NavigationStack
    @State private var viewModel: AccountViewModel = Container.accountViewModel()
    @Bindable private var viewState: ViewState = Container.viewState()
    
    var body: some View {
        let _ = Self._printChanges()
        VStack(spacing: 0) {
            Group {
                AccountView()
                Divider()
                    .frame(height: 1)
                    .overlay(Palette.grayScale2A)
                BalanceView(value: viewModel.totalValue)
                    .frame(height: 98)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .onAppear {
                        viewModel.updateValues()
                    }
                ActionButtonsView
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
            }
            
            Divider()
                .frame(height: 1)
                .overlay(Palette.grayScale10)
            
            if viewModel.items.isEmpty {
                ProgressView()
                    .progressViewStyle(.circular)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.items) { item in
                            ZStack(alignment: .trailing) {
                                WalletItemView(viewModel: item.viewModel)
                                    .padding(.leading, 12)
                                    .padding(.trailing, 22)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        switch item.coin.type {
                                        case .lightningBitcoin:
                                            if viewModel.hasUsableLightningChannel {
                                                navigation.push(.assetDetails(item: item))
                                                withAnimation {
                                                    viewState.hideTabBar = true
                                                }
                                            } else if viewModel.hasLightningChannel {
                                                viewModel.goToLightningChannelAwaits.toggle()
                                            } else {
                                                viewModel.goToLightningChannelSetup.toggle()
                                            }
                                        default:
                                            navigation.push(.assetDetails(item: item))
                                            withAnimation {
                                                viewState.hideTabBar = true
                                            }
                                        }
                                    }
                                Asset.chevronRightIcon
                                    .foregroundColor(Palette.grayScale4A)
                                    .offset(y: 3)
                            }
                            Divider()
                                .frame(height: 1)
                                .overlay(Color(red: 42/255, green: 42/255, blue: 42/255))
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .background(Palette.grayScale20)
            }
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale1A))
        .sheet(isPresented: $viewState.showQRCodeScannerFromTabBar) {
            QRCodeReaderRootView(config: .universal).lockableView()
        }
        .sheet(isPresented: $viewModel.goToReceive, onDismiss: {
            viewModel.updateValues()
        }) {
            let viewModel = ReceiveViewModel.config(items: viewModel.items, selectedItem: nil)
            ReceiveRootView(viewModel: viewModel, withAssetPicker: true).lockableView()
        }
        .sheet(isPresented: $viewModel.goToSend, onDismiss: {
            viewModel.updateValues()
        }) {
            let vm = SendViewViewModel(items: viewModel.items)
            SendRootView(withAssetPicker: true).environment(vm).lockableView()
        }
        .sheet(isPresented: $viewModel.goToLightningChannelSetup, onDismiss: {
            viewModel.updateValues()
        }) {
            CreateChannelRootView(channelIsFunded: viewModel.hasLightningChannel).lockableView()
        }
        .sheet(isPresented: $viewModel.goToLightningChannelAwaits) {
            AwaitsFundingChannelView().lockableView()
        }
        .fullScreenCover(isPresented: $viewState.showBackUpFlow) {
            AccountBackupRootView().environment(viewState).lockableView()
        }
        .fullScreenCover(isPresented: $viewModel.goToSettings) {
            SettingsRootView().lockableView()
        }
    }
    
    func AccountView() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 16, height: 16)
                    Text(viewState.isReachable ? "Online" : "No internet connection")
                        .font(.Main.fixed(.monoRegular, size: 14))

                }
                .foregroundColor(viewState.isReachable ? Color(red: 0.191, green: 0.858, blue: 0.418) : Color.red)
            }
            .padding(.leading, 20)
            
            Spacer()
            
            HStack(spacing: 0) {
                Divider()
                    .frame(width: 1, height: 36)
                    .overlay(Palette.grayScale2A)
                
                if !viewModel.accountDataIsBackedUp {
                    PButton(config: .onlyIcon(Asset.warningIcon), style: .free, size: .medium, color: .yellow, enabled: true) {
                        viewState.showBackUpFlow.toggle()
                    }
                    .frame(width: 30, height: 30)
                    .padding(.leading)
                }
                
                PButton(config: .onlyIcon(Asset.gearIcon), style: .free, size: .medium, color: Palette.grayScale6A, enabled: true) {
                    viewModel.goToSettings.toggle()
                }
                .frame(width: 30, height: 30)
                .padding(.horizontal)
            }
        }
        .frame(height: 42)
        .padding(.horizontal, 6)
    }
    
    func BalanceView(value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(value)
                .font(.Main.fixed(.monoMedium, size: 32))
                .foregroundColor(Palette.grayScaleEA)
            Text(viewModel.fiatCurrency.code.uppercased())
                .font(.Main.fixed(.monoMedium, size: 14))
                .foregroundColor(Palette.grayScale6A)
        }
        .frame(height: 26)
    }
    
    var ActionButtonsView: some View {
        HStack(spacing: 16) {
            PButton(
                config: .labelAndIconLeft(label: "Receive", icon: Asset.receiveButtonIcon),
                style: .outline,
                size: .custom(
                    PButtonConfig(
                        fontSize: 16,
                        spacing: 8,
                        height: 48,
                        cornerRadius: 12,
                        iconSize: 26
                    )
                ),
                color: .white,
                enabled: true
            ) {
                viewModel.goToReceive.toggle()
            }
            
            PButton(
                config: .labelAndIconLeft(label: "Send", icon: Asset.sendButtonIcon),
                style: .outline,
                size: .custom(
                    PButtonConfig(
                        fontSize: 16,
                        spacing: 8,
                        height: 48,
                        cornerRadius: 12,
                        iconSize: 26
                    )
                ),
                enabled: true
            ) {
                viewModel.goToSend.toggle()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.accountViewModel.register { AccountViewModel.mocked }
        
        AccountView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
