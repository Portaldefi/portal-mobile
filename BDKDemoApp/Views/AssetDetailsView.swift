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
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewState: ViewState = Container.viewState()
    @StateObject private var viewModel = AssetDetailsViewModel.config(coin: .bitcoin())
    @State private var showTxDetails = false
    @State private var selectedTx: BitcoinDevKit.Transaction?
    
    let item: WalletItem?
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                HStack {
                    HStack(spacing: 14) {
                        PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                            viewState.hideTabBar = false
                            presentationMode.wrappedValue.dismiss()
                        }
                        .frame(width: 20)
                        
                        Text("All Assets")
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(Palette.grayScaleF4)
                    }
                    Spacer()
                    Asset.gearIcon
                        .foregroundColor(Palette.grayScale6A)
                }
                .frame(height: 48)
                .padding(.horizontal, 20)
                
                Divider()
                    .overlay(Palette.grayScale2A)
                
                if let walletItem = item {
                    WalletItemView(item: walletItem)
                        .padding(.leading, 16)
                        .padding(.vertical, 8)
                }
                
                ActionButtonsView
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
            }
            
            Divider()
                .overlay(Palette.grayScale10)
            
            ZStack {
                ScrollView {
                    ForEach(viewModel.transactions, id: \.self) { transaction in
                        SingleTxView(transaction: transaction)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTx = transaction
                                showTxDetails = true
                            }
                        Divider()
                            .overlay(Palette.grayScale1A)
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
        .navigationBarHidden(true)
        .sheet(isPresented: $viewState.goToReceive) {
            NavigationView {
                ReceiveView(coin: .bitcoin())
            }
        }
        .sheet(isPresented: $viewState.goToSendFromDetails) {
            NavigationView {
                SendView()
            }
        }
        .sheet(isPresented: $showTxDetails) {
            if let tx = selectedTx {
                TransactionDetailsView(coin: viewModel.coin, tx: tx)
            }
        }
    }
    
    var ActionButtonsView: some View {
        HStack(spacing: 10) {
            PButton(
                config: .labelAndIconLeft(label: "Receive", icon: Asset.receiveButtonIcon),
                style: .filled,
                size: .medium,
                enabled: item?.viewModel.coin.name == "Bitcoin" && item?.viewModel.coin.unit == "BTC"
            ) {
                viewState.goToReceive = true
            }
            
            PButton(
                config: .labelAndIconLeft(label: "Send", icon: Asset.sendButtonIcon),
                style: .filled,
                size: .medium,
                enabled: item?.viewModel.coin.name == "Bitcoin" && item?.viewModel.coin.unit == "BTC"
            ) {
                if let item = item {
                    let sendViewViewModel = Container.sendViewModel()
                    sendViewViewModel.selectedItem = item
                    viewState.goToSendFromDetails = true
                }
            }
        }
    }
}

struct TxsView_Previews: PreviewProvider {
    static var previews: some View {
        AssetDetailsView(item: WalletItem.mockedBtc)
    }
}

