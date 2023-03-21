//
//  File.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation
import LightningDevKit

class Logger: LightningDevKit.Logger {
    override func log(record: Bindings.Record) {
        let messageLevel = record.get_level()
        let arguments = record.get_args()
        
        switch messageLevel {
        case LDKLevel_Debug:
            print("\nDebug Logger:\n>\(arguments)\n")
        case LDKLevel_Info:
            print("\nInfo Logger:\n>\(arguments)\n")
        case LDKLevel_Warn:
            print("\nWarn Logger:\n>\(arguments)\n")
        case LDKLevel_Error:
            print("\nError Logger:\n>\(arguments)\n")
        case LDKLevel_Gossip:
            break //print("\nGossip Logger:\n>\(arguments)\n")
        case LDKLevel_Trace:
            print("\nTrace Logger:\n>\(arguments)\n")
        default:
            print("\nUnknown Logger:\n>\(arguments)\n")
        }
    }
}

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
