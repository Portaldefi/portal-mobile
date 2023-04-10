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
            print("LDK LOG - Debug:")
            print("\(arguments)\n")
        case LDKLevel_Info:
            print("LDK LOG - Info:")
            print("\(arguments)\n")
        case LDKLevel_Warn:
            print("LDK LOG - Warn:")
            print("\(arguments)\n")
        case LDKLevel_Error:
            print("LDK LOG - Error:")
            print("\(arguments)\n")
        case LDKLevel_Gossip:
            break //print("\nGossip Logger:\n>\(arguments)\n")
        case LDKLevel_Trace:
            print("LDK LOG - Trace:")
            print("\(arguments)\n")
        default:
            print("LDK LOG - Unknown:")
            print("\(arguments)\n")
        }
    }
}
