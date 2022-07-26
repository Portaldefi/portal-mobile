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
                ZStack {
                    Color(red: 26/255, green: 26/255, blue: 26/255, opacity: 1)
                    
                    VStack(spacing: 0) {
                        BalanceView(balance: viewModel.balance)
                            .padding(.top, 18)
                            .padding(.horizontal, 16)
                            .background(Color(red: 16/255, green: 16/255, blue: 16/255, opacity: 1))
                        ActionButtonsView
                            .padding(.top, 28)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                            .background(Color(red: 16/255, green: 16/255, blue: 16/255, opacity: 1))
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(viewModel.items) { item in
                                    Divider()
                                        .overlay(.black)
                                    WalletItemView(item: item)
                                        .padding(.horizontal, 16)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            goToTxs.toggle()
                                        }
                                    Divider()
                                        .overlay(.black)
                                }
                            }
                            NavigationLink(destination: TxsView(txs: viewModel.transactions), isActive: $goToTxs) { EmptyView() }
                            NavigationLink(destination: SendView(viewModel: viewModel), isActive: $goToSend) { EmptyView() }
                        }
                        
                        Spacer()
                    }
                    .navigationBarHidden(true)
                }
            }
        }.onAppear(perform: viewModel.load)
    }
    
    func BalanceView(balance: UInt64) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                VStack(spacing: 4) {
                    if viewModel.isSynced {
                        HStack(alignment: .bottom, spacing: 10) {
                            Spacer()
                            Text("\(balance)")
                                .font(.system(size: 32, design: .monospaced))
                                .fontWeight(.semibold)
                            Text("sats")
                                .font(.system(size: 18, design: .monospaced))
                                .foregroundColor(Color(red: 138/255, green: 138/255, blue: 138/255, opacity: 1))
                                .padding(.bottom, 4)
                            Spacer()
                        }
                        .frame(height: 32)
                        
                        HStack(spacing: 10) {
                            Text("1 293,00")
                                .font(.system(size: 16, design: .monospaced))
                                .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255, opacity: 1))
                            Text("USD")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                                .offset(y: 2)
                        }
                        .frame(height: 23)
                    } else {
                        Text("Syncing...")
                            .font(.system(size: 32, design: .monospaced))
                            .fontWeight(.semibold)
                            .frame(height: 59)
                    }
                }
            }
            Spacer()
        }
    }
    
    var ActionButtonsView: some View {
        HStack(spacing: 10) {
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
                    .frame(height: 40)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            
            Button {
                
            } label: {
                Text("Swap")
                    .foregroundColor(.black)
                    .font(.system(size: 16, design: .monospaced))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue)
                    .background(in: RoundedRectangle(cornerRadius: 10))
                    .frame(height: 40)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.plain)
            .frame(height: 40)
            
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
                    .frame(height: 40)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            
            NavigationLink(destination: ReceiveView(viewModel: viewModel), isActive: $goToReceive) { EmptyView() }
        }
    }
    
    func WalletItemView(item: WalletItem) -> some View {
        HStack {
            VStack(spacing: 12) {
                VStack(spacing: 4.2) {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8)
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color.green)
                        Text("Bitcoin")
                            .font(.system(size: 14, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255, opacity: 1))
                            .frame(height: 16)
                        Spacer()
                    }
                    HStack(spacing: 6) {
                        Spacer()
                            .frame(width: 16, height: 16)
                        Text(item.description)
                            .font(.system(size: 12, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                            .frame(height: 17)
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(Color(red: 138/255, green: 138/255, blue: 138/255, opacity: 1))
                        Spacer()
                    }
                }
            }
            Spacer()
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Spacer()
                    Text("\(item.balance)")
                        .font(.system(size: 18, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255, opacity: 1))
                    Text("sats")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                }
                .frame(height: 22)
                HStack(spacing: 10) {
                    Spacer()
                    Text("≈ \(item.fiatValue)")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                    Text("USD")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                }
                .frame(height: 22)
            }
        }
        .frame(height: 66)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView(viewModel: WalletViewModel.mocked())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
