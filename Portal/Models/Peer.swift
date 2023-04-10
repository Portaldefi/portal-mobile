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
        let pubKey = "02d47008d34904e4949eb875e00720bd2dfbdbdccf71f38f2822b1697f204d63d9"
        let host = "127.0.0.1"
        let port: UInt16 = 9758
                
        return Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }
    static var bob: Peer {
        let name = "Bob"
        let pubKey = "034ce84cb93a0ecb190cd5b347fd7e9b42d9bd6e1d58f24b6e5518d1ca03da9cb2"
        let host = "127.0.0.1"    //P2p external
        let port: UInt16 = 9759   //in Polar
                
        return Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }
    static var carol: Peer {
        let name = "Carol"
        let pubKey = "03e0c667a8cb90e826e4ccf0db3383ddbf6cef207027c9dc5e3826315c5a822ed8"
        let host = "127.0.0.1"    //P2p external
        let port: UInt16 = 9760   //in Polar
                
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
