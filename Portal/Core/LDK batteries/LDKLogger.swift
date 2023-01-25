//
//  LDKLogger.swift
//  Portal
//
//  Created by farid on 6/13/22.
//

import LightningDevKit

class LDKLogger: Logger {
    override func log(record: Record) {
        let messageLevel = record.getLevel()
        let arguments = record.getArgs()
        
        switch messageLevel {
        case .Debug:
            print("\nDebug Logger:\n>\(arguments)\n")
        case .Info:
            print("\nInfo Logger:\n>\(arguments)\n")
        case .Warn:
            print("\nWarn Logger:\n>\(arguments)\n")
        case .Error:
            print("\nError Logger:\n>\(arguments)\n")
        case .Gossip:
            print("\nGossip Logger:\n>\(arguments)\n")
        case .Trace:
            print("\nSentinel Logger:\n>\(arguments)\n")
        @unknown default:
            print("\nUnknown Logger:\n>\(arguments)\n")
        }
    }

}
