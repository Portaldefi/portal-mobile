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
        WalletItem(description: "Lightning", balance: 2622500),
        WalletItem(description: "On-chain", balance: 26225000 * 3)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            BalanceView(balance: 420000)
                .padding(.horizontal, 16)
            ActionButtonsView
                .padding(.top, 28)
                .padding(.horizontal, 16)
            Divider()
                .padding(.top, 16)
                .padding(.bottom, 20)
            ForEach(items) { item in
                WalletItemView(item: item)
                    .padding(.vertical, 10)
            }
            .padding(.horizontal, 16)
            Spacer()
        }
        .padding(.top, 48)
    }
    
    func BalanceView(balance: Int64) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("total balance")
                    .font(.system(size: 16))
                HStack(alignment: .bottom, spacing: 1) {
                    Text("\(balance)")
                        .fontWeight(.bold)
                        .font(.system(size: 48))
                    Text("sat")
                        .font(.system(size: 16))
                        .padding(.bottom, 10)
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
