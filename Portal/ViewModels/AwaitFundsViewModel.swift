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
    @ObservationIgnored let kit = Container.lightningKitManager()
    var channel: ChannelDetails?
    
    init() {
        if let channelDetails = kit.allChannels.first {
            channel = channelDetails
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
