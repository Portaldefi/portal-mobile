//
//  SingleTxViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 11/3/22.
//

import Foundation
import Combine
import BitcoinDevKit

class SingleTxViewModel: ObservableObject {
    let tx: BitcoinDevKit.TransactionDetails
    
    @Published private(set) var notes: String?
    @Published private(set) var labels: [TxLable]
    
    init(tx: BitcoinDevKit.TransactionDetails) {
        self.tx = tx
        self.notes = tx.notes
        self.labels = tx.labels
    }
}
