//
//  Filter.swift
//  
//
//  Created by farid on 3/24/23.
//

import Foundation
import LightningDevKit

class Filter: LightningDevKit.Filter {
    override func register_tx(txid: [UInt8]?, script_pubkey: [UInt8]) {
        print("filter register txID: \(String(describing: txid?.toHexString()))")
        print("filter register script_pubkey: \(String(describing: script_pubkey.toHexString()))")
    }
    
    override func register_output(output: Bindings.WatchedOutput) -> Bindings.Option_C2Tuple_usizeTransactionZZ {
        let scriptPubkeyBytes = output.get_script_pubkey()
        let outpoint = output.get_outpoint()!
        let txid = outpoint.get_txid()
        let outputIndex = outpoint.get_index()

        // watch for any transactions that spend this output on-chain

        let blockHashBytes = output.get_block_hash()
        // if block hash bytes are not null, return any transaction spending the output that is found in the corresponding block along with its index
        
        return Option_C2Tuple_usizeTransactionZZ.none()
    }
}
