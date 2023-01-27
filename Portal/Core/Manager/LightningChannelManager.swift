//
//  LightningChannelManager.swift
//  Portal
//
//  Created by farid on 6/13/22.
//

import Foundation
//import BitcoinCore
import LightningDevKit

public struct BlockInfo {
    public let height: Int
    public let headerHash: String
}

class LightningChannelManager {
    private var constructor: ChannelManagerConstructor
    
    var channelManager: ChannelManager {
        constructor.channelManager
    }
    
    var payer: InvoicePayer? {
        constructor.payer
    }
    
    var peerManager: PeerManager {
        constructor.peerManager
    }
    
    var peerNetworkHandler: TCPPeerHandler {
        constructor.getTCPPeerHandler()
    }
    
    var chainMonitor: ChainMonitor
    var keysManager: KeysManager
    var channelManagerPersister: ExtendedChannelManagerPersister
    var dataService: ILightningDataService
    private(set) var logger: LDKLogger
    
    init(bestBlock: BlockInfo?, dataService: ILightningDataService, notificationService: INotificationService) {
        self.dataService = dataService
        
        let userConfig: Bindings.UserConfig = .initWithDefault()
        let network: Bindings.Network = .Testnet
        
        let feeEstimator = LDKFeesEstimator()
        let filter = LDKFilter()
        let persister = LDKChannelPersister(dataService: dataService)
        let broadcaster = LDKTestNetBroadcasterInterface()
        logger = LDKLogger()
    
        let seed: [UInt8] = [UInt8](Data(base64Encoded: "13/12//////////////////////////////////11113")!)
        let timestampSeconds = UInt64(Date().timeIntervalSince1970)
        let timestampNanos = UInt32(truncating: NSNumber(value: timestampSeconds * 1000 * 1000))
        
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
                print("fatalError: \(error)")
            }
        } else {
            //start new node
            
            let bestBlock = bestBlock ?? BlockInfo(height: 2278337, headerHash: "000000000000006834c0a2e3507fe17d5ae5fb67e5fd32a1c03583eae7ecf08b")
            let reversedLastBlockHash = bestBlock.headerHash.reversed

            guard
                let chainTipHash = reversedLastBlockHash.hexStringToBytes()
            else {
                fatalError("header hash :/")
            }
        
            let chainTipHeight = UInt32(bestBlock.height)
            
            //test net genesis block hash
            let reversedGenesisBlockHash = "000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943".reversed
            
            guard let genesisHash = reversedGenesisBlockHash.hexStringToBytes() else {
                fatalError("genesisHash :/")
            }
            
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
