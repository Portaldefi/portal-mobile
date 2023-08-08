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
        let pubKey = "031d4f7f926e7b6d74362e5996b67563fef459bbb3465e7da320d932d85786abb6"
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
        let pubKey = "02030e7ed5557c27b8d3ddfe0fcf9297209623af1683e3ca83ad276ceeb451afe1"
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
        let pubKey = "038e6e4a8c1315a6311991ed919a9de052dfcd9c19fa22ca54fc90b64073ff80c2"
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
