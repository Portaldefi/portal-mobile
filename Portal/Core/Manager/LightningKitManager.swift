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
import LightningDevKit
import BitcoinCore
import Factory

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
    
    private var arangurenPeer: Peer {
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
    
    private var strangeironPeer: Peer {
        let name = "STRANGEIRON"
        let pubKey = "0225ff2ae6a3d9722b625072503c2f64f6eddb78d739379d2ee55a16b3b0ed0a17"
        let host = "203.132.94.196"
        let port: UInt16 = 19735
                
        return Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }
    
    init(connectionType: ConnectionType) {
        switch connectionType {
        case .regtest(let config):
            instance = Node(type: .regtest(config))
        case .testnet(let config):
            instance = Node(type: .testnet(config))
        }
        
//        PeerStore.save(peers: [arangurenPeer]) { result in
//            switch result {
//            case .success(let peerCount):
//                print("Saved \(peerCount) peers to disk.")
//            case .failure(_):
//                // FIXME: Handle some saving error
//                print("Error saving peer to disk")
//            }
//        }
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
                            let start = DispatchTime.now()
                            try await connectPeer(peer)
                            let end = DispatchTime.now()
                            
                            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                            let timeInterval = Double(nanoTime)/1_000_000_000
                            print("Peer \(peer.peerPubKey) connected in \(timeInterval) seconds")
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
    
    func createInvoice(amount: String, description: String) async -> String? {
        print(instance.allChannels.count)
        print(instance.usableChannels.count)
        if let amountDouble = Double(amount), amountDouble > 0 {
            let satAmountDouble = amountDouble * 100_000_000
            let satAmountInt = UInt64(satAmountDouble)
            return await instance.createInvoice(satAmount: satAmountInt, description: description)
        }
        return await instance.createInvoice(satAmount: nil, description: description)
    }
    
    func decode(invoice: String) throws -> Invoice? {
        try instance.decode(invoice: invoice)
    }
    
    private func generateKeySeed() {
        let seed = AES.randomIV(32)
        _ = fileManager.persistKeySeed(keySeed: seed)
    }
    
    private func openChannel(peer: Peer) {
        print("opening channel with peer: \(peer.peerPubKey)")
        Task {
            do {
                let channelValue: UInt64 = 20000
                let reserveAmount: UInt64 = 1000
                
                let channelInfo = try await instance.requestChannelOpen(
                    peer.peerPubKey,
                    channelValue: channelValue,
                    reserveAmount: reserveAmount
                )
                
                print("open channel requested")
                
                if let address = decodeAddress(script: channelInfo.fundingOutputScript) {
                    peer.addFundingTransactionPubkey(pubkey: address.stringValue)
                    update(peer: peer)
                    
                    print("decoded address: \(address.stringValue)")
                    
                    let fundingTransaction = try rawTx(amount: channelValue, address: address.stringValue)
                                        
                    if try await instance.openChannel(
                        channelOpenInfo: channelInfo,
                        fundingTransaction: fundingTransaction
                    ) {
                        print("Channel \(channelInfo.temporaryChannelId) is opened")
                    } else {
                        throw ServiceError.cannotOpenChannel
                    }
                }
            } catch {
                print("failed to open channel: \(error.localizedDescription)")
            }
        }
    }
            
    private func update(peer: Peer) {
        PeerStore.update(peer: peer) { result in
            switch result {
            case .success(_):
                print("Saved peer: \(peer.peerPubKey)")
            case .failure(_):
                // TOODO: Handle saving new funding transaction pubkey error
                print("Error persisting new pub key")
            }
        }
    }
    
    private func rawTx(amount: UInt64, address: String) throws -> [UInt8] {
        let adapterManager = Container.adapterManager()
        guard let adapter = adapterManager.adapter(for: .bitcoin()) as? ISendBitcoinAdapter else {
            throw ServiceError.keySeedNotFound
        }
        return try adapter.rawTransaction(amount: amount, address: address)
    }
    
    private func decodeAddress(script: [UInt8]) -> Address? {
        let scriptConverter = ScriptConverter()
        let addressConverter = SegWitBech32AddressConverter(prefix: "tb", scriptConverter: scriptConverter)
        return try? addressConverter.convert(keyHash: Data(script), type: .p2wsh)
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
