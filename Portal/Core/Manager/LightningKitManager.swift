//
//  LightningKitManager.swift
//  Portal
//
//  Created by farid on 6/13/22.
//

import Foundation
import LightningDevKit

public struct BlockInfo {
    public let height: Int
    public let headerHash: String
}

class LightningKitManager {
    private var constructor: ChannelManagerConstructor
    
    var channelManager: ChannelManager {
        constructor.channelManager
    }
    
    var peerManager: PeerManager {
        constructor.peerManager
    }
    
    var peerNetworkHandler: TCPPeerHandler {
        constructor.getTCPPeerHandler()
    }
    
    var payer: InvoicePayer? {
        constructor.payer
    }
    
    private var chainMonitor: ChainMonitor
    private var keysManager: KeysManager
    private var channelManagerPersister: ExtendedChannelManagerPersister
    private var dataService: ILightningDataService
    
    private(set) var logger: LDKLogger
    
    init(bestBlock: BlockInfo?, dataService: ILightningDataService) {
        self.dataService = dataService
        
        let userConfig: Bindings.UserConfig = .initWithDefault()
        let network: Bindings.Network = .Testnet
        
        let feeEstimator = LDKFeesEstimator()
        let filter = LDKFilter()
        let persister = LDKChannelPersister(dataService: dataService)
        let broadcaster = LDKTestNetBroadcasterInterface()
        let timestampSeconds = UInt64(Date().timeIntervalSince1970)
        let timestampNanos = UInt32(truncating: NSNumber(value: timestampSeconds * 1000 * 1000))
        
        logger = LDKLogger()
        
        guard let seedData = Data(base64Encoded: "point head pencil differ reopen damp wink minute improve toward during term") else {
            fatalError("Failed to wrap seed string")
        }
        
        let seed: [UInt8] = [UInt8](seedData)
        
        keysManager = KeysManager(seed: seed, startingTimeSecs: timestampSeconds, startingTimeNanos: timestampNanos)
        
        chainMonitor = ChainMonitor(
            chainSource: filter,
            broadcaster: broadcaster,
            logger: logger,
            feeest: feeEstimator,
            persister: persister
        )
        
        if let channelManagerSerialized = dataService.channelManagerData?.bytes {
            //restoring node
            
            let networkGraphSerizlized = dataService.networkGraph?.bytes ?? []
            let channelMonitorsSeriaziled = dataService.channelMonitors?.map{ $0.bytes } ?? []

            do {
                constructor = try ChannelManagerConstructor(
                    channelManagerSerialized: channelManagerSerialized,
                    channelMonitorsSerialized: channelMonitorsSeriaziled,
                    keysInterface: keysManager.asKeysInterface(),
                    feeEstimator: feeEstimator,
                    chainMonitor: chainMonitor,
                    filter: filter,
                    netGraphSerialized: networkGraphSerizlized,
                    txBroadcaster: broadcaster,
                    logger: logger
                )
            } catch {
                fatalError("\(error)")
            }
        } else {
            //start new node
            
            //test net genesis block hash
            let reversedGenesisBlockHash = "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943".reversed

            guard
                let bestBlock = bestBlock,
                let chainTipHash = bestBlock.headerHash.reversed.hexStringToBytes(),
                let genesisHash = reversedGenesisBlockHash.hexStringToBytes()
            else {
                fatalError("header hash :/")
            }
        
            let chainTipHeight = UInt32(bestBlock.height)
            let networkGraph = NetworkGraph(genesisHash: genesisHash, logger: logger)
            
            constructor = ChannelManagerConstructor(
                network: network,
                config: userConfig,
                currentBlockchainTipHash: chainTipHash,
                currentBlockchainTipHeight: chainTipHeight,
                keysInterface: keysManager.asKeysInterface(),
                feeEstimator: feeEstimator,
                chainMonitor: chainMonitor,
                netGraph: networkGraph,
                txBroadcaster: broadcaster,
                logger: logger
            )
        }
        
        let bestBlockHeight = constructor.channelManager.currentBestBlock().height()
        let bestBlockHash = constructor.channelManager.currentBestBlock().blockHash()
        print("Best block height: \(bestBlockHeight), hash: \(bestBlockHash.toHexString())")
        
        channelManagerPersister = LDKChannelManagerPersister(
            channelManager: constructor.channelManager,
            dataService: dataService
        )
    }
    
    func chainSyncCompleted() {
        if let networkGraph = constructor.netGraph {
            let probabalisticScorer = ProbabilisticScorer(params: .initWithDefault(), networkGraph: networkGraph, logger: logger)
            let score = probabalisticScorer.asScore()
            let multiThreadedScorer = MultiThreadedLockableScore(score: score)
            constructor.chainSyncCompleted(persister: channelManagerPersister, scorer: multiThreadedScorer)
        }
    }
}
