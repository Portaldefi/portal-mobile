//
//  AssetDetailsView.swift
//  BDKDemoApp
//
//  Created by farid on 7/22/22.
//

import SwiftUI
import BitcoinDevKit
import PortalUI
import Factory

struct AssetDetailsView: View {
    @EnvironmentObject private var navigation: NavigationStack
    @ObservedObject private var viewState: ViewState = Container.viewState()
    @ObservedObject private var viewModel: AssetDetailsViewModel
    
    @State private var showTxDetails = false
    @State private var selectedTx: TransactionRecord?
    
    let item: WalletItem
    
    init(item: WalletItem, viewModel: AssetDetailsViewModel) {
        self.item = item
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                HStack {
                    HStack(spacing: 8) {
                        PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                            navigation.pop()
                            withAnimation {
                                viewState.hideTabBar = false
                            }
                        }
                        .frame(width: 20)
                        
                        Text("All Assets")
                            .font(.Main.fixed(.monoBold, size: 16))
                    }
                    Spacer()
                    Asset.gearIcon
                        .foregroundColor(Palette.grayScale6A)
                }
                .frame(height: 48)
                .padding(.horizontal, 20)
                
                Divider()
                    .overlay(Palette.grayScale2A)
                
                if !viewState.isReachable {
                    NoInternetConnectionView()
                }
                                
                WalletItemView(viewModel: item.viewModel)
                    .padding(.leading, 16)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                
                ActionButtonsView
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 8)
            }
            
            Divider()
                .overlay(Palette.grayScale10)
            
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.transactions, id: \.self) { transaction in
                            SingleTxView(transaction: transaction)
                                .padding(.leading, 10)
                                .padding(.trailing, 6)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTx = transaction
                                }
                        }
                    }
                }
                .background(Palette.grayScale20)
                
                if viewModel.transactions.isEmpty {
                    Text("No transactions yet.")
                        .font(.Main.fixed(.monoRegular, size: 16))
                        .padding()
                }
            }
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale1A))
        .sheet(item: $selectedTx, onDismiss: {
            viewModel.updateTransactions()
        }) { tx in
            TransactionDetailsView(coin: viewModel.coin, tx: tx).lockableView()
        }
        .sheet(isPresented: $viewModel.goToReceive, onDismiss: {
            viewModel.updateTransactions()
        }) {
            let account = Container.accountViewModel()
            let item = account.items.first{ $0.coin == viewModel.coin }
            let receiveViewModel = ReceiveViewModel.config(items: account.items, selectedItem: item)
            
            ReceiveRootView(viewModel: receiveViewModel, withAssetPicker: false).lockableView()
        }
        .sheet(isPresented: $viewModel.goSend, onDismiss: {
            viewModel.updateTransactions()
        }) {
            SendRootView(withAssetPicker: false).lockableView()
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
                viewModel.goToReceive = true
            }
            
            PButton(
                config: .labelAndIconLeft(label: "Send", icon: Asset.sendButtonIcon),
                style: .filled,
                size: .medium,
                enabled: item.viewModel.balance > 0
            ) {
                let sendViewViewModel = Container.sendViewModel()
                sendViewViewModel.coin = item.viewModel.coin
                viewModel.goSend.toggle()
            }
        }
    }
}

struct NoInternetConnectionView: View {
    var body: some View {
        HStack {
            Text("No Internet Connection")
                .font(.Main.fixed(.monoSemiBold, size: 14))
                .foregroundColor(.black)
                .padding(6)
        }
        .frame(maxWidth: .infinity)
        .background(Color.red)
    }
}

struct TxsView_Has_Connection: PreviewProvider {
    static var previews: some View {
        let _ = Container.viewState.register { ViewState.mocked(hasConnection: true) }
        AssetDetailsView(item: WalletItem.mockedBtc, viewModel: AssetDetailsViewModel.mocked)
    }
}

struct TxsView_No_Connection: PreviewProvider {
    static var previews: some View {
        let _ = Container.viewState.register { ViewState.mocked(hasConnection: false) }
        AssetDetailsView(item: WalletItem.mockedBtc, viewModel: AssetDetailsViewModel.mocked)
    }
}

