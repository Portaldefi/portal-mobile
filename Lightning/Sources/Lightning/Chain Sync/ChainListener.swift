//
//  ChainListener.swift
//  https://docs.rs/lightning/0.0.112/lightning/chain/trait.Listen.html
//
//  Created by Jurvis on 9/5/22.
//

import Foundation
import LightningDevKit

class ChainListener: Listen {
    private let channelManager: ChannelManager
    private let chainMonitor: ChainMonitor

    init(channelManager: ChannelManager, chainMonitor: ChainMonitor) {
        self.channelManager = channelManager
        self.chainMonitor = chainMonitor
    }
    
    override func blockConnected(block: [UInt8], height: UInt32) {
        print("block connected at height \(height)")
        self.channelManager.asListen().blockConnected(block: block, height: height)
        self.chainMonitor.asListen().blockConnected(block: block, height: height)
    }

    override func blockDisconnected(header: [UInt8]?, height: UInt32) {
        print("block disconnected from height \(height)")
        self.channelManager.asListen().blockDisconnected(header: header, height: height)
        self.chainMonitor.asListen().blockDisconnected(header: header, height: height)
        //self.chainMonitor.asConfirm().transactionsConfirmed(header: <#T##[UInt8]?#>, txdata: <#T##[(UInt, [UInt8])]#>, height: <#T##UInt32#>)
    }
    
    override func filteredBlockConnected(header: [UInt8]?, txdata: [(UInt, [UInt8])], height: UInt32) {
        
    }
}
