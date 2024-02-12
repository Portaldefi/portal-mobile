//
//  File.swift
//  
//
//  Created by Jurvis on 9/4/22.
//
import Foundation

extension URL {
    static var channelManagerDirectory: URL {
        documentsDirectory.appendingPathComponent("channelManager")
    }
    
    static var aliceAdminMacaroon: URL {
        documentsDirectory.appendingPathComponent("alice.macaroon")
    }
    
    static var bobAdminMacaroon: URL {
        documentsDirectory.appendingPathComponent("bob.macaroon")
    }
    
    static var scorerDirectory: URL {
        documentsDirectory.appendingPathComponent("scorer")
    }
    
    static var channelMonitorsDirectory: URL {
        documentsDirectory.appendingPathComponent("channelMonitors", isDirectory: true)
    }
    
    static var keySeedDirectory: URL {
        documentsDirectory.appendingPathComponent("keySeed")
    }
    
    static var networkGraphDirectory: URL {
        documentsDirectory.appendingPathComponent("networkGraph")
    }
    
    static var paymentsDirectory: URL {
        documentsDirectory.appendingPathComponent("lightningPayments", isDirectory: true)
    }
    
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    static func pathForPersistingChannelMonitor(id: String) -> URL? {
        let folderExists = (try? channelMonitorsDirectory.checkResourceIsReachable()) ?? false
        if !folderExists {
            try? FileManager.default.createDirectory(at: channelMonitorsDirectory, withIntermediateDirectories: false)
        }
        
        let fileName = "chanmon_\(id)"
        return channelMonitorsDirectory.appendingPathComponent(fileName)
    }
    
    static func pathForPersistingPayment(id: String) -> URL? {
        let folderExists = (try? paymentsDirectory.checkResourceIsReachable()) ?? false
        if !folderExists {
            try? FileManager.default.createDirectory(at: paymentsDirectory, withIntermediateDirectories: false)
        }
        
        let fileName = "payment_\(id)"
        return paymentsDirectory.appendingPathComponent(fileName)
    }
}
