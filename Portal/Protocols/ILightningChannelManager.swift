//
//  ILightningChannelManager.swift
//  Portal
//
//  Created by farid on 5/16/22.
//  Copyright © 2022 Tides Network. All rights reserved.
//

import Foundation
import LightningDevKit

protocol ILightningChannelManager {
    var payer: InvoicePayer? { get }
    var channelManager: ChannelManager { get }
    var peerManager: PeerManager { get }
    var chainMonitor: ChainMonitor { get }
    var channelManagerPersister: ExtendedChannelManagerPersister { get }
    var keysManager: KeysManager { get }
    var peerNetworkHandler: TCPPeerHandler { get }
    
    func chainSyncCompleted()
}
