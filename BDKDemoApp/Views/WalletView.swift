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
                .padding(.top, 20)
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
                    .textStyle(BasicTextStyle(white: true))
                HStack(alignment: .bottom, spacing: 1) {
                    if viewModel.isSynced {
                        Text("\(balance)")
                            .fontWeight(.bold)
                            .font(.system(size: 48))
                        Text("sats")
                            .font(.system(size: 16))
                            .padding(.bottom, 10)
                    } else {
                        Text("Syncing...")
                            .fontWeight(.bold)
                            .font(.system(size: 48))
                    }
                }
            }
            Spacer()
        }
    }
    
    var ActionButtonsView: some View {
        HStack {
            Button {
                
            } label: {
                Text("Send")
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue)
                    .background(in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            Button {
                
            } label: {
                Text("Receive")
                    .font(.system(size: 18))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue)
                    .background(in: RoundedRectangle(cornerRadius: 8))
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.plain)

            Button {
                
            } label: {
                Text("[ ]")
                    .fontWeight(.semibold)
                    .padding(8)
                    .background(Color.blue)
                    .background(in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }
    
    func WalletItemView(item: WalletItem) -> some View {
        VStack {
            HStack(spacing: 4.8) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color.blue)
                Text(item.description)
                    .font(.system(size: 16))
                Spacer()
            }
            HStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 1) {
                    Text("\(item.balance)")
                        .font(.system(size: 32))
                        .fontWeight(.semibold)
                    Text("sats")
                        .padding(.bottom, 6)
                }
                Spacer()
                HStack(spacing: 1) {
                    Text("$\(item.fiatValue)")
                    Text("USD")
                }
                .padding(.bottom, 6)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
