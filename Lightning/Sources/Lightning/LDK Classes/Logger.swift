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
