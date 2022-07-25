//
//  WalletView.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import SwiftUI

struct WalletView: View {
    @StateObject private var viewModel: WalletViewModel
    
    @State private var goToTxs = false
    @State private var goToReceive = false
    @State private var goToSend = false
    
    init(viewModel: WalletViewModel) {
        UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont.monospacedSystemFont(ofSize: 28, weight: .bold), .foregroundColor: UIColor.white]
        
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationView {
            switch viewModel.state {
            case .empty:
                VStack {Text("error")}
            case .failed(_):
                VStack {Text("error")}
            case .loading:
                VStack {Text("error")}
            case .loaded(_, _):
                VStack(spacing: 0) {
                    BalanceView(balance: viewModel.balance)
                        .padding(.top, 18)
                        .padding(.horizontal, 16)
                    ActionButtonsView
                        .padding(.top, 28)
                        .padding(.horizontal, 16)
                    Divider()
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                    
                    ScrollView {
                        ForEach(viewModel.items) { item in
                            WalletItemView(item: item)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    goToTxs.toggle()
                                }
                        }
                        NavigationLink(destination: TxsView(txs: viewModel.transactions), isActive: $goToTxs) { EmptyView() }
                        NavigationLink(destination: SendView(viewModel: viewModel), isActive: $goToSend) { EmptyView() }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
                .navigationBarHidden(true)
            }
        }.onAppear(perform: viewModel.load)
    }
    
    func BalanceView(balance: UInt64) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("total balance")
                    .font(.system(size: 16, design: .monospaced))
                    .foregroundColor(Color(red: 138/255, green: 138/255, blue: 138/255, opacity: 1))
                HStack(alignment: .bottom, spacing: 0) {
                    if viewModel.isSynced {
                        Text("\(balance)")
                            .font(.system(size: 48, design: .monospaced))
                            .fontWeight(.semibold)
                        Text("sats")
                            .font(.system(size: 16, design: .monospaced))
                            .foregroundColor(Color(red: 138/255, green: 138/255, blue: 138/255, opacity: 1))
                            .padding(.bottom, 10)
                    } else {
                        Text("Syncing...")
                            .font(.system(size: 48, design: .monospaced))
                            .fontWeight(.semibold)
                    }
                }
                .frame(height: 32)
            }
            Spacer()
        }
    }
    
    var ActionButtonsView: some View {
        HStack(spacing: 10) {
            Button {
                goToSend.toggle()
            } label: {
                Text("Send")
                    .foregroundColor(.black)
                    .font(.system(size: 16, design: .monospaced))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue)
                    .background(in: RoundedRectangle(cornerRadius: 10))
                    .frame(height: 30)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            
            Button {
                goToReceive.toggle()
            } label: {
                Text("Receive")
                    .foregroundColor(.black)
                    .font(.system(size: 16, design: .monospaced))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue)
                    .background(in: RoundedRectangle(cornerRadius: 10))
                    .frame(height: 30)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.plain)
            .frame(height: 30)
            
            Button {
                
            } label: {
                Text("Scan")
                    .foregroundColor(.black)
                    .font(.system(size: 16, design: .monospaced))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue)
                    .background(in: RoundedRectangle(cornerRadius: 10))
                    .frame(height: 30)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            
            NavigationLink(destination: ReceiveView(viewModel: viewModel), isActive: $goToReceive) { EmptyView() }
        }
    }
    
    func WalletItemView(item: WalletItem) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 4.8) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color.blue)
                Text(item.description)
                    .font(.system(size: 14.5))
                    .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255, opacity: 1))
                Spacer()
            }
            HStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 1) {
                    Text("\(item.balance)")
                        .font(.system(size: 32, design: .monospaced))
                        .fontWeight(.semibold)
                    Text("sats")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(Color(red: 138/255, green: 138/255, blue: 138/255, opacity: 1))
                        .padding(.bottom, 6)
                }
                .frame(height: 32)
                Spacer()
                HStack(spacing: 1) {
                    Text("$\(item.fiatValue)")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255, opacity: 1))
                    Text("USD")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(Color(red: 138/255, green: 138/255, blue: 138/255, opacity: 1))
                }
                .padding(.bottom, 6)
            }
        }
        .frame(height: 84)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView(viewModel: WalletViewModel.mocked())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
