//
//  SingleTxViewModel.swift
// Portal
//
//  Created by farid on 11/3/22.
//

import Foundation
import Combine
import BitcoinDevKit

class SingleTxViewModel: ObservableObject {
    let coin: Coin
    let tx: TransactionRecord
    
    @Published private(set) var notes: String?
    @Published private(set) var labels: [TxLable]
    
    var value: String {
        guard let amount = tx.amount else { return "0" }
        switch coin.type {
        case .bitcoin:
            return (amount.double/100_000_000).toString(decimal: 8)
        case .ethereum:
            return amount.double.toString(decimal: 8)
        case .erc20:
            return "0"
        case .lightningBitcoin:
            return "0"
        }
    }
        
    init(coin: Coin, tx: TransactionRecord) {
        self.coin = coin
        self.tx = tx
        self.notes = tx.notes
        self.labels = tx.labels
    }
}
