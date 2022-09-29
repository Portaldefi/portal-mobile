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
    @State private var goToTxs = false
    @State private var goToReceive = false
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewState: ViewState = Container.viewState()
    @ObservedObject private var viewModel: AccountViewModel = Container.accountViewModel()
    @ObservedObject private var sendViewModel = Container.sendViewModel()
    
    let item: WalletItem?
    let txs: [BitcoinDevKit.Transaction]
    
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
                    ForEach(txs, id: \.self) { transaction in
                        SingleTxView(transaction: transaction)
                            .padding(.horizontal, 8)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if case .confirmed(let details, _) = transaction {
                                    let urlString = "https://blockstream.info/testnet/tx/\(details.txid)"
                                    if let url = URL(string: urlString) {
#if os(iOS)
                                        UIApplication.shared.open(url)
#elseif os(macOS)
                                        NSWorkspace.shared.open(url)
#endif
                                    }
                                }
                            }
                        Divider()
                            .overlay(Palette.grayScale1A)
                    }
                }
                .background(Palette.grayScale20)
                
                if txs.isEmpty {
                    Text("No transactions yet.")
                        .font(.Main.fixed(.monoRegular, size: 16))
                        .padding()
                }
            }
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale1A))
        .navigationBarHidden(true)
        .sheet(isPresented: $sendViewModel.goToReceive, onDismiss: {
            sendViewModel.goToReceive = false
        }) {
            NavigationView {
                ReceiveView(coin: .bitcoin())
            }
        }
        .sheet(isPresented: $sendViewModel.goToSend, onDismiss: {
            sendViewModel.goToSend = false
        }) {
            NavigationView {
                SendView()
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
                sendViewModel.goToReceive = true
            }
            
            PButton(
                config: .labelAndIconLeft(label: "Send", icon: Asset.sendButtonIcon),
                style: .filled,
                size: .medium,
                enabled: item?.viewModel.coin.name == "Bitcoin" && item?.viewModel.coin.unit == "BTC"
            ) {
                if let item = item {
                    sendViewModel.selectedItem = item
                }
            }
        }
    }
}

struct TxsView_Previews: PreviewProvider {
    static var previews: some View {
        AssetDetailsView(item: WalletItem.mockedBtc, txs: [])
    }
}

