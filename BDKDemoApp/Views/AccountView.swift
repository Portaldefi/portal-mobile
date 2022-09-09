//
//  AccountView.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import SwiftUI
import PortalUI
import Factory

struct AccountView: View {
    @State private var goToDetails = false
    @State private var goToReceive = false
    @State private var selectedItem: WalletItem?
    @State private var qrItem: QRCodeItem?
    
    @ObservedObject private var viewModel: AccountViewModel = Container.accountViewModel()
    @ObservedObject private var viewState: ViewState = Container.viewState()
    
    init() {
        UINavigationBar
            .appearance()
            .largeTitleTextAttributes = [
                .font : UIFont.monospacedSystemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor.white
            ]
    }
    
    var body: some View {
        NavigationView {
            switch viewModel.state {
            case .empty:
                VStack { Text("Empty") }
            case .failed(let error):
                VStack { Text(error.localizedDescription) }
            case .loading:
                VStack { Text("Loading...") }
            case .dbNotFound:
                VStack { Text("DB not founded...") }
            case .loaded:
                ZStack {
                    Color(red: 26/255, green: 26/255, blue: 26/255).ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        Group {
                            AccountView()
                            Divider()
                                .overlay(Color(red: 42/255, green: 42/255, blue: 42/255))
                            BalanceView(balance: viewModel.totalBalance, value: viewModel.value)
                                .frame(height: 124)
                                .padding(.horizontal, 16)
                            ActionButtonsView
                                .padding(.horizontal, 16)
                                .padding(.bottom, 24)
                        }
                        
                        Divider()
                            .overlay(Color(red: 16/255, green: 16/255, blue: 16/255))
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(viewModel.items) { item in
                                    ZStack(alignment: .trailing) {
                                        WalletItemView(item: item)
                                            .padding(.leading, 16)
                                            .padding(.trailing, 10)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                selectedItem = item
                                                goToDetails.toggle()
                                            }
                                        Asset.chevronRightIcon
                                            .foregroundColor(Color(red: 74/255, green: 74/255, blue: 74/255))
                                    }
                                    Divider()
                                        .overlay(Color(red: 22/255, green: 22/255, blue: 22/255))
                                }
                            }
                            NavigationLink(
                                destination: AssetDetailsView(item: selectedItem, txs: viewModel.transactions),
                                isActive: $goToDetails
                            ) {
                                EmptyView()
                            }
                        }
                        .background(Color(red: 32/255, green: 32/255, blue: 32/255))
                        Spacer()
                    }
                    .navigationBarHidden(true)
                }
            }
        }
        .onAppear(perform: viewModel.sync)
        .sheet(isPresented: $viewState.showScanner, onDismiss: {
            viewState.showScanner = false
        }) {
            QRCodeReaderView(config: .universal)
        }
        .sheet(isPresented: $viewState.goToSend, onDismiss: {
            
        }) {
            NavigationView {
                SelectAssetView(qrItem: $qrItem)
            }
        }
    }
    
    func AccountView() -> some View {
        HStack {
            HStack {
                Asset.walletIcon
                    .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                Text(viewModel.accountName)
                    .font(.Main.fixed(.bold, size: 16))
                    .foregroundColor(Color(red: 244/255, green: 244/255, blue: 244/255, opacity: 1))
            }
            Spacer()
            if case .syncing = viewModel.syncState {
                Text("Syncing...")
                    .font(.Main.fixed(.semiBold, size: 12))
                    .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
            }
            Asset.gearIcon
                .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
        }
        .frame(height: 48)
        .padding(.horizontal, 20)
    }
    
    func BalanceView(balance: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                VStack(spacing: 4) {
                    switch viewModel.syncState {
                    case .syncing, .synced:
                        HStack(alignment: .bottom, spacing: 6) {
                            Spacer()
                            Text(balance)
                                .font(.Main.fixed(.bold, size: 32))
                                .foregroundColor(Color(red: 234/255, green: 234/255, blue: 234/255, opacity: 1))
                            Text("sats")
                                .font(.Main.fixed(.regular, size: 18))
                                .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                                .padding(.bottom, 4)
                            Spacer()
                        }
                        .frame(height: 32)
                        .onTapGesture {
                            
                        }
                        
                        HStack(spacing: 4) {
                            Text(value)
                                .font(.Main.fixed(.medium, size: 16))
                                .foregroundColor(Color(red: 234/255, green: 234/255, blue: 234/255, opacity: 1))
                            Text("usd")
                                .font(.Main.fixed(.medium, size: 12))
                                .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                                .offset(y: 2)
                        }
                        .frame(height: 23)
                    case .empty, .failed:
                        EmptyView()
                    }
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
                withAnimation {
                    viewState.goToSend.toggle()
                }
            }
            
            NavigationLink(destination: ReceiveView(viewModel: viewModel), isActive: $goToReceive) { EmptyView() }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
            .environmentObject(ViewState())
            .environmentObject(AccountViewModel.mocked())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
