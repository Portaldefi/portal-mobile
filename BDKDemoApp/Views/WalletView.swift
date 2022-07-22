//
//  WalletView.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import SwiftUI

struct WalletView: View {
    @StateObject private var viewModel = WalletViewModel()
    
    var body: some View {
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
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 100)
            
            ScrollView {
                if viewModel.transactions.isEmpty {
                    Text("No transactions yet.").padding()
                } else {
                    ForEach(viewModel.transactions, id: \.self) { transaction in
                        SingleTxView(transaction: transaction)
                    }
                }
            }
        }
        .onAppear {
            viewModel.load()
        }
    }
    
    func BalanceView(balance: UInt64) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("total balance")
                    .font(.system(size: 16, design: .monospaced))//.weight(bold ? .bold : .regular))
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
                
            } label: {
                Text("Send")
                    .foregroundColor(.black)
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
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
                
            } label: {
                Text("Receive")
                    .foregroundColor(.black)
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
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
                    .font(.system(size: 16))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue)
                    .background(in: RoundedRectangle(cornerRadius: 10))
                    .frame(height: 30)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
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
        WalletView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .preferredColorScheme(.dark)
    }
}
