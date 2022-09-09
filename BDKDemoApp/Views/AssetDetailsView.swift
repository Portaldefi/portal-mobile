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
    @ObservedObject private var viewModel: AccountViewModel = Container.accountViewModel()
    @ObservedObject private var sendViewModel = Container.sendViewModel()
    
    let item: WalletItem?
    let txs: [BitcoinDevKit.Transaction]
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(red: 26/255, green: 26/255, blue: 26/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                Group {
                    HStack {
                        HStack(spacing: 0) {
                            PButton(config: .onlyIcon(Asset.chevronRightIcon), style: .free, size: .medium, enabled: true) {
                                presentationMode.wrappedValue.dismiss()
                            }
                            .frame(width: 20)
                            .rotationEffect(.degrees(180))
                            
                            Text("All Assets")
                                .font(.Main.fixed(.bold, size: 16))
                                .foregroundColor(Color(red: 244/255, green: 244/255, blue: 244/255, opacity: 1))
                        }
                        Spacer()
                        Asset.gearIcon
                            .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 20)
                    
                    Divider()
                        .overlay(Color(red: 42/255, green: 42/255, blue: 42/255))
                    
                    if let walletItem = item {
                        WalletItemView(item: walletItem)
                            .padding(.leading, 16)
                            .padding(.trailing, 8)
                            .padding(.vertical, 8)
                    }
                    
                    ActionButtonsView
                        .padding(.horizontal, 12)
                        .padding(.bottom, 16)
                }
                
                Divider()
                    .overlay(Color(red: 16/255, green: 16/255, blue: 16/255))
                
                ScrollView {
                    if txs.isEmpty {
                        Text("No transactions yet.").padding()
                    } else {
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
                                .overlay(Color(red: 26/255, green: 26/255, blue: 26/255))
                        }
                    }
                }
                .background(Color(red: 32/255, green: 32/255, blue: 32/255))
            }
        }
        .navigationBarHidden(true)
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
                enabled: viewModel.syncState == .synced
            ) {
                goToReceive.toggle()
            }
            
            PButton(
                config: .labelAndIconLeft(label: "Send", icon: Asset.sendButtonIcon),
                style: .filled,
                size: .medium,
                enabled: viewModel.syncState == .synced
            ) {
                if let item = item {
                    sendViewModel.selectedItem = item
                }
//                viewState.goToSend.toggle()
            }
            
            NavigationLink(destination: ReceiveView(viewModel: viewModel), isActive: $goToReceive) { EmptyView() }
        }
    }
}

struct TxsView_Previews: PreviewProvider {
    static var previews: some View {
        AssetDetailsView(item: WalletItem(icon: Asset.btcIcon, chainIcon: Asset.chainIcon, name: "Bitcoin", description: "Chain", balance: "0", unit: "btc", value: "$0"), txs: [])
    }
}

