//
//  AssetView.swift
//  BDKDemoApp
//
//  Created by farid on 7/22/22.
//

import SwiftUI
import BitcoinDevKit
import PortalUI
import Factory

struct AssetView: View {
    @Environment(NavigationStack.self) var navigation: NavigationStack
    @State private var showChannelDetails = false
    @State private var viewModel: AssetViewModel
    @State private var showTxDetails = false
    
    let item: WalletItem
    
    private var viewState: ViewState = Container.viewState()
        
    init(item: WalletItem, viewModel: AssetViewModel) {
        self.item = item
        self._viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            let _ = Self._printChanges()
            Group {
                HStack {
                    Button {
                        navigation.pop()
                        withAnimation {
                            viewState.hideTabBar = false
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Asset.caretLeftIcon
                            Text("All Assets")
                                .font(.Main.fixed(.bold, size: 16))
                                .foregroundColor(Palette.grayScale8A)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    if item.coin == .lightningBitcoin() {
                        PButton(config: .onlyIcon(Asset.gearIcon), style: .free, size: .medium, color: Palette.grayScale6A, enabled: true) {
                            showChannelDetails.toggle()
                        }
                        .frame(width: 30, height: 30)
                    }
                }
                .frame(height: 48)
                .padding(.horizontal, 20)
                
                Divider()
                    .overlay(Palette.grayScale2A)
                
                if !viewState.isReachable {
                    NoInternetConnectionView()
                }
                                
                WalletItemView(viewModel: item.viewModel)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 24)
                
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
                                    viewModel.selectedTx = transaction
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
        .onAppear {
            viewModel.updateTransactions()
        }
        .sheet(item: $viewModel.selectedTx) { tx in
            TransactionView(coin: viewModel.coin, tx: tx).lockableView()
        }
        .sheet(isPresented: $viewModel.goToReceive) {
            let account = Container.accountViewModel()
            let item = account.items.first{ $0.coin == viewModel.coin }
            let receiveViewModel = ReceiveViewModel.config(items: account.items, selectedItem: item)
            
           ReceiveRootView(viewModel: receiveViewModel, withAssetPicker: false).lockableView()
        }
        .sheet(isPresented: $viewModel.goSend) {
            SendRootView(withAssetPicker: false).environment(Container.sendViewModel()).lockableView()
        }
        .sheet(isPresented: $showChannelDetails) {
            LNChannelView()
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
        AssetView(item: WalletItem.mockedBtc, viewModel: AssetViewModel.mocked)
    }
}

struct TxsView_No_Connection: PreviewProvider {
    static var previews: some View {
        let _ = Container.viewState.register { ViewState.mocked(hasConnection: false) }
        AssetView(item: WalletItem.mockedBtc, viewModel: AssetViewModel.mocked)
    }
}

