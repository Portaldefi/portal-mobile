//
//  WalletView.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import SwiftUI

struct WalletItem: Identifiable {
    let id: UUID = UUID()
    let description: String
    let balance: Int64
    
    var fiatValue: Int64 {
        balance/1000
    }
}

struct WalletView: View {
    private let items: [WalletItem] = [
        WalletItem(description: "Lightning", balance: 26225000),
        WalletItem(description: "On-chain", balance: 26225000 * 3)
    ]
    
    var body: some View {
        VStack {
            BalanceView(balance: 420000)
                .padding(.horizontal, 16)
            ActionButtonsView
                .padding(.horizontal, 16)
            Divider()
                .padding(.top, 16)
                .padding(.bottom, 20)
            ForEach(items) { item in
                WalletItemView(item: item)
            }
            .padding(.horizontal, 16)
            Spacer()
        }
        .padding(.top, 48)
    }
    
    func BalanceView(balance: Int64) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text("total balance")
                HStack(spacing: 1) {
                    Text("\(balance)")
                    Text("sat")
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
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.yellow)
            }

            Button {
                
            } label: {
                Text("Receive")
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.yellow)
            }
            .frame(maxWidth: .infinity)

            Button {
                
            } label: {
                Text("[ ]")
                    .padding(8)
                    .background(Color.yellow)
                    .background(in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    func WalletItemView(item: WalletItem) -> some View {
        VStack {
            HStack(spacing: 4.8) {
                RoundedRectangle(cornerRadius: 8)
                    .frame(width: 16, height: 16)
                    .foregroundColor(Color.blue)
                Text(item.description)
                Spacer()
            }
            HStack {
                HStack(spacing: 1) {
                    Text("\(item.balance)")
                    Text("sats")
                }
                Spacer()
                HStack(spacing: 1) {
                    Text("\(item.fiatValue)")
                    Text("USD")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        WalletView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
