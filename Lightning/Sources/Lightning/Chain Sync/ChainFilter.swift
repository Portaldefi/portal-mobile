//
//  ChainFilter.swift
//  An implementation of [`chain::Filter`](https://docs.rs/lightning/latest/lightning/chain/trait.Filter.html)
//  that will allow us to use a chain source like Electrum
//
//  Created by Jurvis on 9/5/22.
//

import Foundation
import LightningDevKit

class ChainFilter: Filter {
    // A tuple containing both the transaction txid (which can be nil) and script pubkey
    typealias FilterTransaction = ([UInt8]?, [UInt8])
    
    // Transactions and outputs we want to pay attention to.
    var watchedTransactions = [FilterTransaction]()
    var watchedOutputs = [WatchedOutput]()
    
    override func registerTx(txid: [UInt8]?, scriptPubkey: [UInt8]) {
        watchedTransactions.append((txid, scriptPubkey))
    }
    
    override func registerOutput(output: WatchedOutput) {
        self.watchedOutputs.append(output)
    }
}
