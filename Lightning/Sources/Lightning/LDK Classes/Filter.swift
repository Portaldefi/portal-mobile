//
//  Filter.swift
//  
//
//  Created by farid on 3/24/23.
//

import Foundation
import LightningDevKit

class Filter: LightningDevKit.Filter {
    override func registerTx(txid: [UInt8]?, scriptPubkey: [UInt8]) {
        print("filter register txID: \(String(describing: txid?.toHexString()))")
        print("filter register script_pubkey: \(String(describing: scriptPubkey.toHexString()))")
    }
    
    override func registerOutput(output: Bindings.WatchedOutput) {
        let scriptPubkeyBytes = output.getScriptPubkey()
        let outpoint = output.getOutpoint()
        let txid = outpoint.getTxid()
        let outputIndex = outpoint.getIndex()

        // watch for any transactions that spend this output on-chain

        let blockHashBytes = output.getBlockHash()
        // if block hash bytes are not null, return any transaction spending the output that is found in the corresponding block along with its index
    }
}
