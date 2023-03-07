//
//  ChannelPersister.swift
//  
//
//  Created by Jurvis on 9/5/22.
//

import Foundation
import LightningDevKit

class ChannelPersister: Persist {
    override func persistNewChannel(channelId: Bindings.OutPoint, data: Bindings.ChannelMonitor, updateId: Bindings.MonitorUpdateId) -> Bindings.ChannelMonitorUpdateStatus {
        let idBytes: [UInt8] = channelId.write()
        let monitorBytes: [UInt8] = data.write()
        
        let channelMonitor = ChannelMonitor(idBytes: idBytes, monitorBytes: monitorBytes)
        
        do {
            try persistChannelMonitor(channelMonitor, for: channelId.write().toHexString())
        } catch {
            print("\(#function) error: \(error)")
            return .PermanentFailure
        }
        
        return .Completed
    }
    
    override func updatePersistedChannel(channelId: Bindings.OutPoint, update: Bindings.ChannelMonitorUpdate, data: Bindings.ChannelMonitor, updateId: Bindings.MonitorUpdateId) -> Bindings.ChannelMonitorUpdateStatus {
        let idBytes: [UInt8] = channelId.write()
        let monitorBytes: [UInt8] = data.write()
        
        let channelMonitor = ChannelMonitor(idBytes: idBytes, monitorBytes: monitorBytes)
        do {
            try persistChannelMonitor(channelMonitor, for: idBytes.toHexString())
        } catch {
            print("\(#function) error: \(error)")
            return .PermanentFailure
        }
        
        return .Completed
    }
    
    func persistChannelMonitor(_ channelMonitor: ChannelMonitor, for channelId: String) throws {
        guard let pathToPersist = URL.pathForPersistingChannelMonitor(id: channelId) else {
            throw ChannelPersisterError.invalidPath
        }

        do {
           let data = try NSKeyedArchiver.archivedData(
               withRootObject: channelMonitor,
               requiringSecureCoding: false
           )
           try data.write(to: pathToPersist)
        } catch {
           throw error
        }
    }
}

// MARK: Errors
extension ChannelPersister {
    public enum ChannelPersisterError: Error {
        case invalidPath
    }
}
