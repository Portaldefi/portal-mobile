//
//  LightningChannel.swift
//  Portal
//
//  Created by farid on 6/6/22.
//

import Foundation

class LightningChannel: Identifiable {
    enum State: Int16 {
        case waitingFunds = 0, open, closed
        
        var description: String {
            switch self {
            case .waitingFunds:
                return "Funding"
            case .open:
                return "Open"
            case .closed:
                return "Closed"
            }
        }
    }
    let id: UInt16
    let nodeAlias: String
    var satValue: UInt64
    var state: State
    
    init(id: Int16, satValue: Int64, state: State, nodeAlias: String) {
        self.id = UInt16(id)
        self.nodeAlias = nodeAlias
        self.satValue = UInt64(satValue)
        self.state = state
    }
    
//    init(record: DBLightningChannel) {
//        self.id = UInt16(record.channelID)
//        self.nodeAlias = record.node.alias
//        self.satValue = UInt64(record.satValue)
//        self.state = State.init(rawValue: record.state)!
//    }
}
