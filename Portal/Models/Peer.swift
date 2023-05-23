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
        let pubKey = "025f3afd463c9c2d535241a130879326e2c8320ba58f9253d523be3939af7aa114"
        let host = "127.0.0.1"
        let port: UInt16 = 9735
                
        return Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }
    static var bob: Peer {
        let name = "Bob"
        let pubKey = "02f16b6cbcadede7a6fc4bff1ffa39a01bb7fedc3b38b8637746b4684beb533ca3"
        let host = "127.0.0.1"    //P2p external
        let port: UInt16 = 9736   //in Polar
                
        return Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }
    static var carol: Peer {
        let name = "Carol"
        let pubKey = "032ee612780f5e9c0ab56dfd269ce8d8e7cebeb31bc88f92bcf2fcbe8e9128d14d"
        let host = "127.0.0.1"    //P2p external
        let port: UInt16 = 9737   //in Polar
                
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
