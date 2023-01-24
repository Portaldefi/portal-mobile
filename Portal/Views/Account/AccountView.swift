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
    @State private var goToReceive = false
    @State private var selectedItem: WalletItem?
    @State private var qrItem: QRCodeItem?
    
    @EnvironmentObject private var navigation: NavigationStack
    @ObservedObject private var viewModel: AccountViewModel = Container.accountViewModel()
    @ObservedObject private var viewState: ViewState = Container.viewState()
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                AccountView()
                Divider()
                    .overlay(Palette.grayScale2A)
                BalanceView(balance: viewModel.totalBalance, value: viewModel.totalValue)
                    .frame(height: 124)
                    .padding(.horizontal, 16)
                ActionButtonsView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
            }
            
            Divider()
                .overlay(Palette.grayScale10)
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.items) { item in
                        ZStack(alignment: .trailing) {
                            WalletItemView(viewModel: item.viewModel)
                                .padding(.leading, 16)
                                .padding(.trailing, 8)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation {
                                        viewState.hideTabBar = true
                                    }
                                    selectedItem = item
                                    
                                    navigation.push(.assetDetails(item: item))
                                }
                            Asset.chevronRightIcon
                                .foregroundColor(Palette.grayScale4A)
                        }
                        Divider()
                            .overlay(Color(red: 42/255, green: 42/255, blue: 42/255))
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(Palette.grayScale20)
        }
        .navigationBarHidden(true)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale1A))
        .sheet(isPresented: $viewState.showQRCodeScannerFromTabBar) {
            QRCodeReaderView(config: .universal)
        }
        .sheet(isPresented: $goToReceive) {
            let viewModel = ReceiveViewModel.config(items: viewModel.items, selectedItem: nil)
            
            ReceiveRootView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewState.goToSend) {
            SendRootView()
        }
        .fullScreenCover(isPresented: $viewState.goToBackUp) {
            AccountBackupRootView()
        }
    }
    
    func AccountView() -> some View {
        HStack {
            HStack {
                Asset.walletIcon
                    .foregroundColor(Palette.grayScale6A)
                Text(viewModel.accountName)
                    .font(.Main.fixed(.bold, size: 16))
                    .foregroundColor(Palette.grayScaleF4)
            }
            
            Spacer()
            
            if !viewModel.accountDataIsBackedUp {
                PButton(config: .onlyIcon(Asset.warningIcon), style: .free, size: .medium, color: .yellow, enabled: true) {
                    viewState.goToBackUp.toggle()
                }
                .frame(width: 30, height: 30)
            }
            
            Asset.gearIcon
                .foregroundColor(Palette.grayScale6A)
        }
        .frame(height: 48)
        .padding(.horizontal, 20)
    }
    
    func BalanceView(balance: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                VStack(spacing: 4) {
                    HStack(alignment: .bottom, spacing: 6) {
                        Spacer()
                        Text(balance)
                            .font(.Main.fixed(.monoBold, size: 32))
                            .foregroundColor(Palette.grayScaleEA)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text("btc")
                            .font(.Main.fixed(.monoRegular, size: 18))
                            .foregroundColor(Palette.grayScale6A)
                            .padding(.bottom, 4)
                        Spacer()
                    }
                    .frame(height: 32)
                    .onTapGesture {
                        
                    }
                    
                    HStack(spacing: 4) {
                        Text(value)
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Palette.grayScaleEA)
                        Text("usd")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Palette.grayScale6A)
                            .offset(y: 2)
                    }
                    .frame(height: 23)
                }
            }
            Spacer()
        }
    }
    
    var ActionButtonsView: some View {
        HStack(spacing: 10) {
            PButton(
                config: .labelAndIconLeft(label: "Receive", icon: Asset.receiveButtonIcon),
                style: .filled,
                size: .medium,
                enabled: true
            ) {
                goToReceive.toggle()
            }
            
            PButton(
                config: .labelAndIconLeft(label: "Send", icon: Asset.sendButtonIcon),
                style: .filled,
                size: .medium,
                enabled: true
            ) {
                withAnimation {
                    viewState.goToSend.toggle()
                }
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
