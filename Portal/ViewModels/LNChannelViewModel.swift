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

class LNChannelViewModel: ObservableObject {
    private let ldkManager = Container.lightningKitManager()
    
    @Published var peers: [String] = []
    @Published var showError: Bool = false
    @Published var showConfirmationPopup = false
    @Published var errorMessage: String = String()
    @Published var isOpeningChannel: Bool = false
    
    var allChannels: [ChannelDetails] {
        ldkManager.allChannels
    }
    
    var usableChannels: [ChannelDetails] {
        ldkManager.usableChannels
    }
    
    init() {
        ldkManager.activePeersPublisher.assign(to: &$peers)
    }
    
    func openChannel(peer: Peer) async {
        do {
            try await ldkManager.openChannel(peer: peer)
            DispatchQueue.main.async {
                self.errorMessage = "Channel is opened! Wait for fundind tx is confirmed on-chain"
                self.isOpeningChannel.toggle()
                self.showError.toggle()
            }
        } catch {
            DispatchQueue.main.async {
                if let apiError = error as? NodeError.Channels {
                    self.errorMessage = apiError.description
                } else {
                    self.errorMessage = error.localizedDescription
                }
                self.showError.toggle()
                self.isOpeningChannel.toggle()
            }
        }
    }
    
    func connect(peer: Peer) async {
        do {
            try await ldkManager.connectPeer(peer)
            DispatchQueue.main.async {
                self.errorMessage = "Connected to \(peer.name)"
                self.showError.toggle()
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed connect to \(peer.name)"
                self.showError.toggle()
            }
        }
    }
    
    func disconnect(peer: Peer) {
        do {
            try ldkManager.disconnectPeer(peer)
            DispatchQueue.main.async {
                self.errorMessage = "Disconnected from \(peer.name)"
                self.showError.toggle()
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed connect disconnect \(peer.name)"
                self.showError.toggle()
            }
        }
    }
    
    func cooperativeCloseChannel(id: [UInt8], counterPartyId: [UInt8]) {
        print("=====Cooperativly closing channel=====\nwith id: \(id.toHexString())\ncounterparty id: \(counterPartyId.toHexString())\n=====")
        ldkManager.cooperativeCloseChannel(id: id, counterPartyId: counterPartyId)
    }
    
    func forceCloseChannel(id: [UInt8], counterPartyId: [UInt8]) {
        print("=====Force closing channel=====\nwith id: \(id.toHexString())\ncounterparty id: \(counterPartyId.toHexString())\n=====")
        ldkManager.forceCloseChannel(id: id, counterPartyId: counterPartyId)
    }
}

