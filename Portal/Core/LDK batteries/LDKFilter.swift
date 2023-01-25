//
//  LDKFilter.swift
//  Portal
//
//  Created by farid on 6/13/22.
//

import LightningDevKit

class LDKFilter: Filter {
//    override func register_tx(txid: [UInt8]?, script_pubkey: [UInt8]) {
//        // watch this transaction on-chain
//    }
//
//    override func register_output(output: WatchedOutput) -> Option_C2Tuple_usizeTransactionZZ {
////        let scriptPubkeyBytes = output.get_script_pubkey()
////        let outpoint = output.get_outpoint()!
////        let txid = outpoint.get_txid()
////        let outputIndex = outpoint.get_index()
////
////        // watch for any transactions that spend this output on-chain
////
////        let blockHashBytes = output.get_block_hash()
////        // if block hash bytes are not null, return any transaction spending the output that is found in the corresponding block along with its index
//
//        return Option_C2Tuple_usizeTransactionZZ.none()
//    }
    
    override func registerTx(txid: [UInt8]?, scriptPubkey: [UInt8]) {
        
    }
    
    override func registerOutput(output: Bindings.WatchedOutput) {
        
    }
}
