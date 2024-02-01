//
//  AwaitFundsViewModel.swift
//  Portal
//
//  Created by farid on 20.12.2023.
//

import Foundation
import Factory
import LightningDevKit

@Observable class AwaitsFundingViewModel {
    let peer: Peer?
    let channel: ChannelDetails?
    
    @ObservationIgnored let kit = Container.lightningKitManager()
    
    init() {
        if let channelDetails = kit.allChannels.first {
            channel = channelDetails
        } else {
            channel = nil
        }
        
        if let peerData = UserDefaults.standard.data(forKey: "NodeToConnect"),
           let peer = try? JSONDecoder().decode(Peer.self, from: peerData)
        {
            self.peer = peer
        } else {
            peer = nil
        }
    }
    
    var totalConfirmationsRequiredString: String {
        if let value = totalConfirmationsRequired {
            return String(describing: value)
        } else {
            return "unknown"
        }
    }
    
    var confirmationsString: String {
        if let value = confirmations {
            return String(describing: value)
        } else {
            return "unknown"
        }
    }
    
    var confirmations: UInt32? {
        channel?.getConfirmations()
    }
    
    var totalConfirmationsRequired: UInt32? {
        channel?.getConfirmationsRequired()
    }
    
}
