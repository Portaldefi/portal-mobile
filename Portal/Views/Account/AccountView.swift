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
    @EnvironmentObject private var navigation: NavigationStack
    @ObservedObject private var viewModel: AccountViewModel = Container.accountViewModel()
    @ObservedObject private var viewState: ViewState = Container.viewState()
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                AccountView()
                Divider()
                    .frame(height: 1)
                    .overlay(Palette.grayScale2A)
                BalanceView(balance: viewModel.totalBalance, value: viewModel.totalValue)
                    .frame(height: 124)
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
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.items) { item in
                        ZStack(alignment: .trailing) {
                            WalletItemView(viewModel: item.viewModel)
                                .padding(.leading, 16)
                                .padding(.trailing, 10)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation {
                                        viewState.hideTabBar = true
                                    }
                                    navigation.push(.assetDetails(item: item))
                                }
                            Asset.chevronRightIcon
                                .foregroundColor(Palette.grayScale4A)
                                .offset(x: 5)
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
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale1A))
        .sheet(isPresented: $viewState.showQRCodeScannerFromTabBar) {
            QRCodeReaderRootView(config: .universal)
        }
        .sheet(isPresented: $viewModel.goToReceive) {
            let viewModel = ReceiveViewModel.config(items: viewModel.items, selectedItem: nil)
            ReceiveRootView(viewModel: viewModel, withAssetPicker: true)
        }
        .sheet(isPresented: $viewModel.goToSend, onDismiss: {
            viewModel.updateValues()
        }) {
            SendRootView(withAssetPicker: true)
        }
        .fullScreenCover(isPresented: $viewState.showBackUpFlow) {
            AccountBackupRootView().environmentObject(viewState)
        }
    }
    
    func AccountView() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.accountName)
                    .font(.Main.fixed(.bold, size: 24))
                    .foregroundColor(Palette.grayScaleF4)

                HStack {
                    RoundedRectangle(cornerRadius: 4)
                        .frame(width: 16, height: 16)
                    Text("All systems ok!")
                        .font(.Main.fixed(.monoRegular, size: 14))

                }
                .foregroundColor(Color(red: 0.191, green: 0.858, blue: 0.418))
            }
            .padding(.bottom)
            .padding(.leading, 20)
            
            Spacer()
            
            HStack(spacing: 0) {
                Divider()
                    .frame(width: 1, height: 70)
                    .overlay(Palette.grayScale2A)
                
                if !viewModel.accountDataIsBackedUp {
                    PButton(config: .onlyIcon(Asset.warningIcon), style: .free, size: .medium, color: .yellow, enabled: true) {
                        viewState.showBackUpFlow.toggle()
                    }
                    .frame(width: 30, height: 30)
                    .padding(.leading)
                }
                
                Asset.gearIcon
                    .foregroundColor(Palette.grayScale6A)
                    .padding()
            }
        }
        .frame(height: 73)
        .padding(.horizontal, 6)
    }
    
    func BalanceView(balance: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                VStack(spacing: 4) {
                    HStack(alignment: .lastTextBaseline, spacing: 6) {
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
