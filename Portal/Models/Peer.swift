//
//  Peer.swift
//  Portal
//
//  Created by farid on 1/5/23.
//


import Foundation

class Peer: Codable, Equatable {
    let id: UUID
    let peerPubKey: String
    let name: String
    let connectionInformation: PeerConnectionInformation
    var pendingFundingTransactionPubKeys: [String] = []
        
    internal init(id: UUID = UUID(), peerPubKey: String, name: String, connectionInformation: PeerConnectionInformation) {
        self.id = id
        self.peerPubKey = peerPubKey
        self.name = name
        self.connectionInformation = connectionInformation
    }
        
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            self.pendingFundingTransactionPubKeys = try container.decode([String].self, forKey: .pendingFundingTransactionPubKeys)
       } catch {
           self.pendingFundingTransactionPubKeys = []
       }
        
        self.id = try container.decode(UUID.self, forKey: .id)
        self.peerPubKey = try container.decode(String.self, forKey: .peerPubKey)
        self.name = try container.decode(String.self, forKey: .name)
        self.connectionInformation = try container.decode(Peer.PeerConnectionInformation.self, forKey: .connectionInformation)
    }
    
    func addFundingTransactionPubkey(pubkey: String) {
        pendingFundingTransactionPubKeys.append(pubkey)
    }
}

extension Peer {
    static var alice: Peer {
        let name = "Alice"
        let pubKey = "03486d52d6c69a36a57d725a3545ca20c89e5c2c75d3bd9b7e99e7f4b658baf811"
        let host = "127.0.0.1"
        let port: UInt16 = 9001
                
        return Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }
    static var bob: Peer {
        let name = "Bob"
        let pubKey = "0283c749c27b93515313f7875f21a678ec00ffed863e2c6d72008704df15780efd"
        let host = "127.0.0.1"
        let port: UInt16 = 9002
                
        return Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }
}

// MARK: Helper Models
extension Peer {
    struct PeerConnectionInformation: Codable {
        let hostname: String
        let port: UInt16
    }
}

extension Peer: Identifiable, Hashable {
    var identifier: String {
        peerPubKey
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    public static func == (lhs: Peer, rhs: Peer) -> Bool {
        lhs.peerPubKey == rhs.peerPubKey
    }
}
