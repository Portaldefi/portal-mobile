//
//  TxsView.swift
//  BDKDemoApp
//
//  Created by farid on 7/22/22.
//

import SwiftUI
import BitcoinDevKit

struct TxsView: View {
    let txs: [BitcoinDevKit.Transaction]
    
    var body: some View {
        ScrollView {
            if txs.isEmpty {
                Text("No transactions yet.").padding()
            } else {
                ForEach(txs, id: \.self) { transaction in
                    SingleTxView(transaction: transaction)
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
                }
            }
        }
        .navigationTitle("Transactions")
        .modifier(BackButtonModifier())
    }
}

struct TxsView_Previews: PreviewProvider {
    static var previews: some View {
        TxsView(txs: [])
    }
}

