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

class LightningKitManager: ILightningKitManager {
    private let instance: Node
    private let fileManager = LightningFileManager()
    
    private var started = false
    private var cancellabels = Set<AnyCancellable>()
    
    var activePeersPublisher: AnyPublisher<[String], Never> {
        instance.connectedPeers
    }
    
    init(connectionType: ConnectionType) {
        switch connectionType {
        case .regtest(let config):
            instance = Node(type: .regtest(config))
        case .testnet(let config):
            instance = Node(type: .testnet(config))
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
            
            PeerStore.load { [unowned self] result in
                switch result {
                case .success(let peers):
                    for peer in peers.values {
                        Task {
                            try! await instance.connectPeer(
                                pubKey: peer.peerPubKey,
                                hostname: peer.connectionInformation.hostname,
                                port: peer.connectionInformation.port
                            )
                        }
                    }
                case .failure:
                    print("Error loading peers from disk.")
                }
            }
        } catch {
            throw error
        }
    }
    
    func connectPeer(_ peer: Peer) async throws {
        try await instance.connectPeer(
            pubKey: peer.peerPubKey,
            hostname: peer.connectionInformation.hostname,
            port: peer.connectionInformation.port
        )
    }
    
    func requestChannelOpen(_ pubKeyHex: String, channelValue: UInt64, reserveAmount: UInt64) async throws -> String {
        do {
            let channelOpenInfo = try await instance.requestChannelOpen(
                pubKeyHex,
                channelValue: channelValue,
                reserveAmount: reserveAmount
            )
            
            if let scriptPubKey = await instance.getFundingTransactionScriptPubKey(outputScript: channelOpenInfo.fundingOutputScript) {
                return scriptPubKey
            } else {
                throw ServiceError.cannotOpenChannel
            }
        } catch {
            throw ServiceError.cannotOpenChannel
        }
    }
    
    func createInvoice(amount: String, description: String) async -> String? {
        if let amountDouble = Double(amount), amountDouble > 0 {
            let satAmountDouble = amountDouble * 100_000_000
            let satAmountInt = UInt64(satAmountDouble)
            return await instance.createInvoice(satAmount: satAmountInt, description: description)
        }
        return await instance.createInvoice(satAmount: nil, description: description)
    }
    
    private func generateKeySeed() {
        let seed = AES.randomIV(32)
        _ = fileManager.persistKeySeed(keySeed: seed)
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
