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
    //Playnet peers
    static var alice: Peer {
        let name = "Alice"
        let pubKey = "038fa0a228939e7164d76a5bd211d9fec248d17476c1e30fe6c2b37736d8476004"
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
        let pubKey = "0338b91ec1c39260ac18e723abd65d82828aa5cb994f646c9377897ed33cffd0d9"
        let host = "127.0.0.1"
        let port: UInt16 = 9002
                
        return Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }
    //Public peers in testnet
    static var wangOne: Peer {
        let name = "WagOne"
        let pubKey = "03b05b2b15cad59018428d6088dc12ee6ea9758d6743eeace71a19b65f5e05b457"
        let host = "128.16.7.139"
        let port: UInt16 = 9735
                
        return Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }
    
    static var wangTwo: Peer {
        let name = "WagTwo"
        let pubKey = "03320eaaa83c6e7c4ca4199b5d672d3c19961b0f73c4a005f9b42dc376e23ca6dd"
        let host = "3.86.28.215"
        let port: UInt16 = 9735
        
        return Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }
    
    static var mlCom: Peer {
        let name = "1ML.com node ALPHA"
        let pubKey = "02312627fdf07fbdd7e5ddb136611bdde9b00d26821d14d94891395452f67af248"
        let host = "23.237.77.12"
        let port: UInt16 = 9735
        
        return Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }
    
    static var olympus: Peer {
        let name = "OLYMPUS by ZEUS"
        let pubKey = "03e84a109cd70e57864274932fc87c5e6434c59ebb8e6e7d28532219ba38f7f6df"
        let host = "139.144.22.237"
        let port: UInt16 = 9735
        
        return Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }
    
    static var openNode: Peer {
        let name = "OpenNode"
        let pubKey = "02eadbd9e7557375161df8b646776a547c5cbc2e95b3071ec81553f8ec2cea3b8c"
        let host = "18.191.253.246"
        let port: UInt16 = 9735
        
        return Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }
    
    static var aranguren: Peer {
        let name = "aranguren.org"
        let pubKey = "038863cf8ab91046230f561cd5b386cbff8309fa02e3f0c3ed161a3aeb64a643b9"
        let host = "203.132.94.196"
        let port: UInt16 = 9735
        
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
