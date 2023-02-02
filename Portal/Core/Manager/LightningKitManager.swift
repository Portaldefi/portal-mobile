//
//  LightningKitManager.swift
//  Portal
//
//  Created by farid on 6/13/22.
//

import Foundation
import Combine
import Lightning
import CryptoSwift

public struct BlockInfo {
    public let height: Int
    public let headerHash: String
}

class LightningKitManager {
    private let instance: Node
    private let fileManager = LightningFileManager()
    
    private var started = false
    private var cancellabels = Set<AnyCancellable>()
    
    init(connectionType: ConnectionType) {
        switch connectionType {
        case .regtest(let config):
            instance = Node(type: .regtest(config))
        case .testnet:
            fatalError("Not implemented!")
        }
    }
    
    func start() async throws {
        guard !started else { throw ServiceError.alreadyRunning }
        
        // FIXME: Make this data write await-able
        if !fileManager.hasKeySeed {
            generateKeySeed()
        }
        
        guard let _ = fileManager.getKeysSeed() else { throw ServiceError.keySeedNotFound }
        
        do {
            try await instance.start()
        } catch {
            throw error
        }
    }
    
    func connectPeer(_ peer: Peer) async throws {
        try await instance.connectPeer(pubKey: peer.peerPubKey, hostname: peer.connectionInformation.hostname, port: peer.connectionInformation.port)
    }
}

// MARK: Helpers
extension LightningKitManager {
    func generateKeySeed() {
        let seed = AES.randomIV(32)
        _ = fileManager.persistKeySeed(keySeed: seed)
    }
}

// MARK: Publishers
extension LightningKitManager {
    var activePeersPublisher: AnyPublisher<[String], Never> {
        return instance.connectedPeers
    }
}

// MARK: Errors
extension LightningKitManager {
    public enum ServiceError: Error {
        case alreadyRunning
        case invalidHash
        case cannotOpenChannel
        case keySeedNotFound
    }
}
