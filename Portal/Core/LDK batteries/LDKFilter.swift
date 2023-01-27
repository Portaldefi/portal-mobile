//
//  LDKFilter.swift
//  Portal
//
//  Created by farid on 6/13/22.
//

import LightningDevKit

class LDKFilter: Filter {
    override func registerTx(txid: [UInt8]?, scriptPubkey: [UInt8]) {
    
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
