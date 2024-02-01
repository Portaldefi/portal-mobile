//
//  LNChannelViewModel.swift
//  Portal
//
//  Created by farid on 18.01.2024.
//

import Foundation
import Factory
import LightningDevKit
import Lightning
import Combine

class LNChannelViewModel: ObservableObject {
    enum AlertType {
        case cooperativeClose, forceClose
    }
    
    private let ldkManager = Container.lightningKitManager()
    
    @Published var peers: [String] = []
    @Published var message: String = String()
    @Published var showMessage: Bool = false
    @Published var isOpeningChannel: Bool = false
    
    @Published var peer: Peer?
    @Published var showChannelCloseAlert = false
    @Published private(set) var alertType: AlertType = .cooperativeClose
    
    var allChannels: [ChannelDetails] {
        ldkManager.allChannels
    }
    
    var usableChannels: [ChannelDetails] {
        ldkManager.usableChannels
    }
    
    init() {
        ldkManager.activePeersPublisher.assign(to: &$peers)
        
        if
            let peerData = UserDefaults.standard.data(forKey: "NodeToConnect"),
            let peer = try? JSONDecoder().decode(Peer.self, from: peerData)
        {
            self.peer = peer
        }
    }
    
    func openChannel(peer: Peer) async {
        let msg: String
        
        do {
            try await ldkManager.openChannel(peer: peer, amount: 2500)
            msg = "Channel is opened! Wait for fundind tx is confirmed on-chain"
        } catch {
            if let apiError = error as? NodeError.Channels {
                msg = apiError.description
            } else {
                msg = error.localizedDescription
            }
        }
        
        DispatchQueue.main.async {
            self.message = msg
            self.isOpeningChannel.toggle()
            self.showMessage.toggle()
        }
    }
    
    func connect(peer: Peer) async {
        let msg: String

        do {
            try await ldkManager.connectPeer(peer)
            msg = "Connected to \(peer.name)"
        } catch {
            msg = "Failed connect to \(peer.name)"
        }
        
        DispatchQueue.main.async {
            self.message = msg
            self.showMessage.toggle()
        }
    }
    
    func disconnect(peer: Peer) {
        let msg: String
        
        do {
            try ldkManager.disconnectPeer(peer)
            msg = "Disconnected from \(peer.name)"
        } catch {
            msg = "Failed connect disconnect \(peer.name)"
        }
        
        DispatchQueue.main.async {
            self.message = msg
            self.showMessage.toggle()
        }
    }
    
    func showChannelChannelClose(type: AlertType) {
        switch type {
        case .cooperativeClose:
            alertType = .cooperativeClose
        case .forceClose:
            alertType = .forceClose
        }
        showChannelCloseAlert.toggle()
    }
    
    func cooperativeClose() {
        guard let channel = usableChannels.first, let channelId = channel.getChannelId() else {
            print("cooperativeClose error: Cannot get channel data")
            return
        }
        let counterPartyId = channel.getCounterparty().getNodeId()
        cooperativeCloseChannel(id: channelId, counterPartyId: counterPartyId)
        UserDefaults.standard.set(Data(), forKey: "NodeToConnect")
    }
    
    func forceClose() {
        guard let channel = usableChannels.first, let channelId = channel.getChannelId() else {
            print("forceClose error: Cannot get channel data")
            return
        }
        let counterPartyId = channel.getCounterparty().getNodeId()
        forceCloseChannel(id: channelId, counterPartyId: counterPartyId)
        UserDefaults.standard.set(Data(), forKey: "NodeToConnect")
    }
    
    private func cooperativeCloseChannel(id: [UInt8], counterPartyId: [UInt8]) {
        print("=====Cooperativly closing channel=====\nwith id: \(id.toHexString())\ncounterparty id: \(counterPartyId.toHexString())\n=====")
        ldkManager.cooperativeCloseChannel(id: id, counterPartyId: counterPartyId)
    }
    
    private func forceCloseChannel(id: [UInt8], counterPartyId: [UInt8]) {
        print("=====Force closing channel=====\nwith id: \(id.toHexString())\ncounterparty id: \(counterPartyId.toHexString())\n=====")
        ldkManager.forceCloseChannel(id: id, counterPartyId: counterPartyId)
    }
}

