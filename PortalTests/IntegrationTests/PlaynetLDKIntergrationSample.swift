//
//  PlaynetLDKIntergrationSample.swift
//  PortalTests
//
//  Created by farid on 23.08.2023.
//

import LightningDevKit
@testable import Portal

@available(iOS 15.0, *)
public class PlaynetLDKIntergrationSample {

    enum TestFlowExceptions: Error {
        case unexpectedChannelManagerEventType
        case missingInvoicePayer
        case invoiceParsingError(ParseOrSemanticError)
        case hexParsingError
        case invalidOutputScript
        case outputScriptMissingAddresses
        case paymentPathUnsuccessful
        case fundingTxError
        case failedToConnectToAlice
        case gotChannelCloseEvent(String)
    }

    static let WALLET_NAME = "PLAYNET_LDK_INTEGRATION_TEST_WALLET"
    static let MOCK_OUTPUT_SCRIPT: [UInt8] = [0, 1, 0]

    // EDIT ME
    static let PLAYNET_ALICE_PEER_PUBKEY_HEX = "0283c749c27b93515313f7875f21a678ec00ffed863e2c6d72008704df15780efd"
    static let PLAYNET_ALICE_PEER_INVOICE =  "lnbcrt10u1pjw363ypp56zqry69d2qt3qdwtjflg5y86jspcacuk6emdk627hk0lwjpq2c0qdqqcqzzsxqyz5vqsp55a6dtlpg9t55t3g6rykm4v3u4fyf5g4e7rghtq5n8d4xmzvwhfcq9qyyssqvf352myxe35zjaknnwczvpd02rtmgw8jezmrfqa6jck6neydesp3h3ugn3e6qwht7acwh0p3tf8tljys2kdsrru8w2908gwplv2x3dqqzvahsx"

    func testLDKSetupWithPlaynet() async throws {
        let rpcInterface = try RegtestBlockchainManager(rpcProtocol: .http, rpcDomain: "localhost", rpcPort: 18443, rpcUsername: "lnd", rpcPassword: "lnd")
//        let help = try await rpcInterface.getHelp()
//        print(help)

        try await addFundsToTestWalletIfNeeded(rpcInterface: rpcInterface)
        try await rpcInterface.preloadMonitor(anchorHeight: .chaintip)
        
        var seed = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, seed.count, &seed)

        let timestamp_seconds = UInt64(NSDate().timeIntervalSince1970)
        let timestamp_nanos = UInt32(truncating: NSNumber(value: timestamp_seconds * 1000 * 1000))
        let keysManager = KeysManager(seed: seed, startingTimeSecs: timestamp_seconds, startingTimeNanos: timestamp_nanos)
        let logger = LDKTraitImplementations.PlaynetLogger()

        let config = UserConfig.initWithDefault()
        let lightningNetwork: Network = .Regtest
        let genesisHash = try await rpcInterface.getBlockHash(height: 0)
        let reversedGenesisHash = [UInt8](genesisHash.reversed())
        let chaintipHash = try await rpcInterface.getChaintipHash()
        let reversedChaintipHash = [UInt8](chaintipHash.reversed())
        let chaintipHeight = try await rpcInterface.getChaintipHeight()
        let networkGraph = NetworkGraph(network: .Regtest, logger: logger)

        let scoringParams = ProbabilisticScoringParameters.initWithDefault()
        let probabalisticScorer = ProbabilisticScorer(params: scoringParams, networkGraph: networkGraph, logger: logger)
        let score = probabalisticScorer.asScore()
        let multiThreadedScorer = MultiThreadedLockableScore(score: score)

        print("Genesis hash: \(PlaynetLDKIntergrationSample.bytesToHexString(bytes: genesisHash))")
        print("Genesis hash reversed: \(PlaynetLDKIntergrationSample.bytesToHexString(bytes: reversedGenesisHash))")
        print("Block 1 hash: \(try await rpcInterface.getBlockHashHex(height: 1))")
        print("Block 2 hash: \(try await rpcInterface.getBlockHashHex(height: 2))")
        print("Chaintip hash: \(PlaynetLDKIntergrationSample.bytesToHexString(bytes: chaintipHash))")
        print("Chaintip hash reversed: \(PlaynetLDKIntergrationSample.bytesToHexString(bytes: reversedChaintipHash))")

        let feeEstimator = LDKTraitImplementations.PlaynetFeeEstimator()
        let broadcaster = LDKTraitImplementations.PlaynetBroadcaster(rpcInterface: rpcInterface)
        
        let channelMonitorPersister = LDKTraitImplementations.PlaynetChannelMonitorPersister()
        let channelManagerAndNetworkGraphPersisterAndEventHandler = LDKTraitImplementations.PlaynetChannelManagerAndNetworkGraphPersisterAndEventHandler()
        let chainMonitor = ChainMonitor(chainSource: nil, broadcaster: broadcaster, logger: logger, feeest: feeEstimator, persister: channelMonitorPersister)
        
        let channelManagerConstructorParameters = ChannelManagerConstructionParameters(
            config: config,
            entropySource: keysManager.asEntropySource(),
            nodeSigner: keysManager.asNodeSigner(),
            signerProvider: keysManager.asSignerProvider(),
            feeEstimator: feeEstimator,
            chainMonitor: chainMonitor,
            txBroadcaster: broadcaster,
            logger: logger,
            enableP2PGossip: true,
            scorer: multiThreadedScorer
        )
        
        let channelManagerConstructor = ChannelManagerConstructor(network: lightningNetwork, currentBlockchainTipHash: reversedChaintipHash, currentBlockchainTipHeight: UInt32(chaintipHeight), netGraph: networkGraph, params: channelManagerConstructorParameters)
        let channelManager = channelManagerConstructor.channelManager
        let peerManager = channelManagerConstructor.peerManager
        let tcpPeerHandler = channelManagerConstructor.getTCPPeerHandler()
        
        if let netGraph = channelManagerConstructor.netGraph {
            print("net graph available!")
        }

        let listener = Listener(channelManager: channelManager, chainMonitor: chainMonitor)
        rpcInterface.registerListener(listener)
        async let _: () = try rpcInterface.monitorBlockchain()
        channelManagerConstructor.chainSyncCompleted(persister: channelManagerAndNetworkGraphPersisterAndEventHandler)

        guard let lndPubkey = PlaynetLDKIntergrationSample.hexStringToBytes(hexString: PlaynetLDKIntergrationSample.PLAYNET_ALICE_PEER_PUBKEY_HEX) else {
            throw TestFlowExceptions.hexParsingError
        }
        guard tcpPeerHandler.connect(address: "127.0.0.1", port: 9002, theirNodeId: lndPubkey) else {
            throw TestFlowExceptions.failedToConnectToAlice
        }

        // sleep for one second
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let connectedPeers = peerManager.getPeerNodeIds()
        
        guard !connectedPeers.isEmpty else {
            throw TestFlowExceptions.failedToConnectToAlice
        }

        let channelValue: UInt64 = 1_300_000 // 1.3 million satoshis (0.013 BTC)
        let channelValueBtcString = "0.013"
        let reserveAmount: UInt64 = 1000 // a thousand satoshis reserve
        let userChannelId: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...UInt8.max) }
        let channelOpenResult = channelManager.createChannel(theirNetworkKey: lndPubkey, channelValueSatoshis: channelValue, pushMsat: reserveAmount, userChannelId: userChannelId, overrideConfig: config)

        if let channelOpenError = channelOpenResult.getError() {
            print("error type: \(channelOpenError.getValueType())")
            if let error = channelOpenError.getValueAsApiMisuseError() {
                print("API misuse error: \(error.getErr())")
                throw TestFlowExceptions.gotChannelCloseEvent("API misuse error: \(error.getErr())")
            } else if let error = channelOpenError.getValueAsChannelUnavailable() {
                print("channel unavailable error: \(error.getErr())")
                throw TestFlowExceptions.gotChannelCloseEvent("channel unavailable error: \(error.getErr())")
            } else if let error = channelOpenError.getValueAsFeeRateTooHigh() {
                print("excessive fee rate error: \(error.getErr())")
                throw TestFlowExceptions.gotChannelCloseEvent("excessive fee rate error: \(error.getErr())")
            } else if let error = channelOpenError.getValueAsIncompatibleShutdownScript() {
                print("incompatible shutdown script: \(error.getScript())")
                throw TestFlowExceptions.gotChannelCloseEvent("incompatible shutdown script: \(error.getScript())")
            } else if let error = channelOpenError.getValueAsInvalidRoute() {
                print("route error: \(error.getErr())")
                throw TestFlowExceptions.gotChannelCloseEvent("route error: \(error.getErr())")
            }
        }

        let managerEvents = await channelManagerAndNetworkGraphPersisterAndEventHandler.getManagerEvents(expectedCount: 1)

        let managerEvent = managerEvents[0]
        print("Get event value type: \(managerEvent.getValueType())")

        if let channelClosedEvent = managerEvent.getValueAsChannelClosed() {
            let reason = channelClosedEvent.getReason()
            print("close reason: \(reason.getValueType()) \(reason)")
            if let preciseReason = reason.getValueAsProcessingError() {
                let errorString = preciseReason.getErr()
                print("processing error: \(errorString)")
            } else if let preciseReason = reason.getValueAsCounterpartyForceClosed() {
                print("peer message: \(preciseReason.getPeerMsg())")
            }
        }

        guard let fundingReadyEvent = managerEvent.getValueAsFundingGenerationReady() else {
            throw TestFlowExceptions.unexpectedChannelManagerEventType
        }
        
        let fundingOutputScript = fundingReadyEvent.getOutputScript()
        let temporaryChannelId = fundingReadyEvent.getTemporaryChannelId()

        let outputScriptDetails = try await rpcInterface.decodeScript(script: fundingOutputScript)
        guard let outputScriptAddress = outputScriptDetails["address"] as? String else {
            throw TestFlowExceptions.outputScriptMissingAddresses
        }
        
        let fundingTxid = try await rpcInterface.sendPayment(destinationAddress: outputScriptAddress, amount: channelValueBtcString)
        let fundingTransaction = try await rpcInterface.getTransaction(hash: fundingTxid)
        let fundingTxResult = channelManager.fundingTransactionGenerated(temporaryChannelId: temporaryChannelId, counterpartyNodeId: lndPubkey, fundingTransaction: fundingTransaction)
        
        guard fundingTxResult.isOk() else {
            throw TestFlowExceptions.fundingTxError
        }

        // let's add confirmations
        let fAddress = try await self.getMockAddress(rpcInterface: rpcInterface)
        let minedBlocks = try await rpcInterface.mineBlocks(number: 6, coinbaseDestinationAddress: fAddress)

        var usableChannels = [ChannelDetails]()
        while (usableChannels.isEmpty) {
            usableChannels = channelManager.listUsableChannels()
            // sleep for 100ms
            try await Task.sleep(nanoseconds: 0_100_000_000)
        }
        
        print("Usable channels: \(usableChannels)")
        
        let events = await channelManagerAndNetworkGraphPersisterAndEventHandler.getManagerEvents(expectedCount: 1)
        let channelReadyEvent = events[0]
        
        guard let channelReady = channelReadyEvent.getValueAsChannelReady() else {
            throw TestFlowExceptions.unexpectedChannelManagerEventType
        }
        
        print("Channel ready")
        
        let invoiceResult = Invoice.fromStr(s: PlaynetLDKIntergrationSample.PLAYNET_ALICE_PEER_INVOICE)

        guard let invoice = invoiceResult.getValue() else {
            throw TestFlowExceptions.invoiceParsingError(invoiceResult.getError()!)
        }
        
        print("Invoice parsed")
        
        let invoicePaymentResult = Bindings.payInvoice(invoice: invoice, retryStrategy: .initWithAttempts(a: 3), channelmanager: channelManager)
        
        print("Paying invoice")

        do {
            // process payment
            let events = await channelManagerAndNetworkGraphPersisterAndEventHandler.getManagerEvents(expectedCount: 2)
            let paymentSentEvent = events[0]
            let paymentPathSuccessfulEvent = events[1]
            guard let paymentSent = paymentSentEvent.getValueAsPaymentSent() else {
                throw TestFlowExceptions.unexpectedChannelManagerEventType
            }
            guard let paymentPathSuccessful = paymentPathSuccessfulEvent.getValueAsPaymentPathSuccessful() else {
                throw TestFlowExceptions.paymentPathUnsuccessful
            }
            print("sent payment \(paymentSent.getPaymentId().toHexString()) with fee \(String(describing: paymentSent.getFeePaidMsat())) via \(paymentPathSuccessful.getPath().map { h in h.getShortChannelId() })")
        }
        
//        for _ in 0...600 {
//            // sleep for 100ms
//            try await Task.sleep(nanoseconds: 0_100_000_000)
//        }
        
        print("Peer nodes ids: \(channelManagerConstructor.peerManager.getPeerNodeIds())")
        print("Test \(#function) is done")
    }

    private func addFundsToTestWalletIfNeeded(rpcInterface: RegtestBlockchainManager) async throws {
        let availableWallets = try await rpcInterface.listAvailableWallets()
        let walletNames = (availableWallets["wallets"] as! [[String: Any]]).map { dictionary -> String in
            dictionary["name"] as! String
        }

        if !walletNames.contains(PlaynetLDKIntergrationSample.WALLET_NAME) {
            // if a wallet is already loaded, this will load it also
            let newWallet = try await rpcInterface.createWallet(name: PlaynetLDKIntergrationSample.WALLET_NAME)
            print("Created wallet with name: \(String(describing: newWallet["name"]))")
        }

        let loadedWallets = try await rpcInterface.listLoadedWallets()
        let isPlaynetWalletLoaded = loadedWallets.contains(PlaynetLDKIntergrationSample.WALLET_NAME)
        for currentWalletName in loadedWallets {
            if currentWalletName == PlaynetLDKIntergrationSample.WALLET_NAME {
                continue
            }
            let unloadedWallet = try await rpcInterface.unloadWallet(name: currentWalletName)
            print("Wallet named: \(String(describing: unloadedWallet["name"])) is unloaded")
        }

        if !isPlaynetWalletLoaded {
            let _ = try await rpcInterface.loadWallet(name: PlaynetLDKIntergrationSample.WALLET_NAME)
        }

        let walletInfo = try await rpcInterface.getWalletInfo()
        print("Test wallet info: \(walletInfo)")
        let walletBalance = try await rpcInterface.getWalletBalance()

        if walletBalance < 1 {
            print("Wallet balance of \(walletBalance) too low, mining some blocks")
            let address = try await rpcInterface.generateAddress()
            let _ = try await rpcInterface.mineBlocks(number: 1, coinbaseDestinationAddress: address)

            let fakeAddress = try await self.getMockAddress(rpcInterface: rpcInterface)
            let _ = try await rpcInterface.mineBlocks(number: 50, coinbaseDestinationAddress: fakeAddress)

            let updatedWalletBalance = try await rpcInterface.getWalletBalance()
            let balanceIncrease = updatedWalletBalance - walletBalance
            print("New wallet balance: \(updatedWalletBalance) (increase of \(balanceIncrease))")
        }
    }

    private func getMockAddress(rpcInterface: RegtestBlockchainManager) async throws -> String {
        let scriptDetails = try await rpcInterface.decodeScript(script: PlaynetLDKIntergrationSample.MOCK_OUTPUT_SCRIPT)
        let fakeAddress = ((scriptDetails["segwit"] as! [String: Any])["address"] as! String)
        return fakeAddress
    }
    
    public class MultiPeerSimulator {
        private var rpcInterface: BlockchainObserver!
        private var keysManager: KeysManager!
        private var config: UserConfig!
        private var networkGraph: NetworkGraph!
        private var multiThreadedScorer: MultiThreadedLockableScore!
        private var feeEstimator: FeeEstimator!
        private var broadcaster: BroadcasterInterface!
        private var logger: Logger!
        
        public var channelManagerConstructor: ChannelManagerConstructor!
        
        public func simulateMultiplePeers() async throws {
            print("bindings version: \(Bindings.getLDKSwiftBindingsVersion())")
            
            /*
            let username = ProcessInfo.processInfo.environment["BITCOIN_REGTEST_RPC_USERNAME"] ?? "lnd" // "alice"
            let password = ProcessInfo.processInfo.environment["BITCOIN_REGTEST_RPC_PASSWORD"] ?? "lnd" // "DONT_USE_THIS_YOU_WILL_GET_ROBBED"
            rpcInterface = try BlockchainObserver(rpcProtocol: .http, rpcDomain: "localhost", rpcPort: 8332, rpcUsername: username, rpcPassword: password)
            try await rpcInterface.preloadMonitor(anchorHeight: .chaintip)
            */
            
            var seed = [UInt8](repeating: 0, count: 32)
            let status = SecRandomCopyBytes(kSecRandomDefault, seed.count, &seed)

            let timestamp_seconds = UInt64(NSDate().timeIntervalSince1970)
            let timestamp_nanos = UInt32(truncating: NSNumber(value: timestamp_seconds * 1000 * 1000))
            keysManager = KeysManager(seed: seed, startingTimeSecs: timestamp_seconds, startingTimeNanos: timestamp_nanos)
            logger = LDKTraitImplementations.MuteLogger()

            config = UserConfig.initWithDefault()
            let lightningNetwork = LDKNetwork_Bitcoin
            /*
            let genesisHash = try await rpcInterface.getBlockHash(height: 0)
            let reversedGenesisHash = [UInt8](genesisHash.reversed())
            let chaintipHash = try await rpcInterface.getChaintipHash()
            let reversedChaintipHash = [UInt8](chaintipHash.reversed())
            let chaintipHeight = try await rpcInterface.getChaintipHeight()
            */
            let reversedGenesisHashHex = "6fe28c0ab6f1b372c1a6a246ae63f74f931e8365e15a089c68d6190000000000"
            let reversedGenesisHash = PlaynetLDKIntergrationSample.hexStringToBytes(hexString: reversedGenesisHashHex)!
            let chaintipHeight = 0
            let reversedChaintipHash = reversedGenesisHash
            networkGraph = NetworkGraph(network: .Regtest, logger: logger)
            
            print("Genesis hash reversed: \(PlaynetLDKIntergrationSample.bytesToHexString(bytes: reversedGenesisHash))")

            let scoringParams = ProbabilisticScoringParameters.initWithDefault()
            let probabalisticScorer = ProbabilisticScorer(params: scoringParams, networkGraph: networkGraph, logger: logger)
            let score = probabalisticScorer.asScore()
            multiThreadedScorer = MultiThreadedLockableScore(score: score)
            
            feeEstimator = LDKTraitImplementations.PlaynetFeeEstimator()
            broadcaster = LDKTraitImplementations.MuteBroadcaster()
            
            let channelMonitorPersister = LDKTraitImplementations.PlaynetChannelMonitorPersister()
            let channelManagerAndNetworkGraphPersisterAndEventHandler = LDKTraitImplementations.PlaynetChannelManagerAndNetworkGraphPersisterAndEventHandler()
            let chainMonitor = ChainMonitor(chainSource: nil, broadcaster: broadcaster, logger: logger, feeest: feeEstimator, persister: channelMonitorPersister)

            let channelManagerConstructorParameters = ChannelManagerConstructionParameters(
                config: config,
                entropySource: keysManager.asEntropySource(),
                nodeSigner: keysManager.asNodeSigner(),
                signerProvider: keysManager.asSignerProvider(),
                feeEstimator: feeEstimator,
                chainMonitor: chainMonitor,
                txBroadcaster: broadcaster,
                logger: logger,
                enableP2PGossip: true,
                scorer: multiThreadedScorer
            )
            
            let channelManagerConstructor = ChannelManagerConstructor(network: .Regtest, currentBlockchainTipHash: reversedChaintipHash, currentBlockchainTipHeight: UInt32(chaintipHeight), netGraph: networkGraph, params: channelManagerConstructorParameters)

            let channelManager = channelManagerConstructor.channelManager
            let peerManager = channelManagerConstructor.peerManager
            let tcpPeerHandler = channelManagerConstructor.getTCPPeerHandler()
            
            channelManagerConstructor.chainSyncCompleted(persister: channelManagerAndNetworkGraphPersisterAndEventHandler)
            
            let interPeerConnectionInterval = 0
            let pauseForNextPeer = { () async in
                for _ in 0..<(interPeerConnectionInterval * 10) {
                    // sleep for 100ms
                    try! await Task.sleep(nanoseconds: 0_100_000_000)
                }
            }
            
            print("increasing log threshold")
            Bindings.setLogThreshold(severity: .WARNING)
            
            do {
                // bitrefill
                print("connecting bitrefill")
                let connectionResult = tcpPeerHandler.connect(address: "52.50.244.44", port: 9735, theirNodeId: PlaynetLDKIntergrationSample.hexStringToBytes(hexString: "030c3f19d742ca294a55c00376b3b355c3c90d61c6b6b39554dbc7ac19b141c14f")!)
                print("bitrefill connection success: \(connectionResult)")
                await pauseForNextPeer()
            }
            
            do {
                // River
                print("connecting river")
                let connectionResult = tcpPeerHandler.connect(address: "104.196.249.140", port: 9735, theirNodeId: PlaynetLDKIntergrationSample.hexStringToBytes(hexString: "03037dc08e9ac63b82581f79b662a4d0ceca8a8ca162b1af3551595b8f2d97b70a")!)
                print("river connection success: \(connectionResult)")
                await pauseForNextPeer()
            }
            
            do {
                // Acinq
                print("connecting acinq")
                let connectionResult = tcpPeerHandler.connect(address: "3.33.236.230", port: 9735, theirNodeId: PlaynetLDKIntergrationSample.hexStringToBytes(hexString: "03864ef025fde8fb587d989186ce6a4a186895ee44a926bfc370e2c366597a3f8f")!)
                print("acinq connection success: \(connectionResult)")
                await pauseForNextPeer()
            }
            
            do {
                // Kraken
                print("connecting kraken")
                let connectionResult = tcpPeerHandler.connect(address: "52.13.118.208", port: 9735, theirNodeId: PlaynetLDKIntergrationSample.hexStringToBytes(hexString: "02f1a8c87607f415c8f22c00593002775941dea48869ce23096af27b0cfdcc0b69")!)
                print("kraken connection success: \(connectionResult)")
                await pauseForNextPeer()
            }
            
            do {
                // Matt
                print("connecting matt")
                let connectionResult = tcpPeerHandler.connect(address: "69.59.18.80", port: 9735, theirNodeId: PlaynetLDKIntergrationSample.hexStringToBytes(hexString: "03db10aa09ff04d3568b0621750794063df401e6853c79a21a83e1a3f3b5bfb0c8")!)
                print("matt connection success: \(connectionResult)")
                await pauseForNextPeer()
            }
            
            do {
                // Fold
                print("connecting fold")
                let connectionResult = tcpPeerHandler.connect(address: "35.238.153.25", port: 9735, theirNodeId: PlaynetLDKIntergrationSample.hexStringToBytes(hexString: "02816caed43171d3c9854e3b0ab2cf0c42be086ff1bd4005acc2a5f7db70d83774")!)
                print("fold connection success: \(connectionResult)")
                await pauseForNextPeer()
            }
            
            do {
                // wallet of satoshi
                print("connecting wallet of satoshi")
                let connectionResult = tcpPeerHandler.connect(address: "170.75.163.209", port: 9735, theirNodeId: PlaynetLDKIntergrationSample.hexStringToBytes(hexString: "035e4ff418fc8b5554c5d9eea66396c227bd429a3251c8cbc711002ba215bfc226")!)
                print("wallet of satoshi connection success: \(connectionResult)")
                await pauseForNextPeer()
            }
            
            /*
            struct Listener: BlockchainListener {
                private let channelManager: ChannelManager
                private let chainMonitor: ChainMonitor

                init(channelManager: ChannelManager, chainMonitor: ChainMonitor) {
                    self.channelManager = channelManager
                    self.chainMonitor = chainMonitor
                }

                func blockConnected(block: [UInt8], height: UInt32) {
                    self.channelManager.as_Listen().block_connected(block: block, height: height)
                    self.chainMonitor.as_Listen().block_connected(block: block, height: height)
                }

                func blockDisconnected(header: [UInt8]?, height: UInt32) {
                    self.chainMonitor.as_Listen().block_disconnected(header: header, height: height)
                    self.channelManager.as_Listen().block_disconnected(header: header, height: height)
                }
            }


            let listener = Listener(channelManager: channelManager, chainMonitor: chainMonitor)
            rpcInterface.registerListener(listener)
            async let monitor = try rpcInterface.monitorBlockchain()
            */
            
            // channelManagerConstructor.chain_sync_completed(persister: channelManagerAndNetworkGraphPersisterAndEventHandler, scorer: multiThreadedScorer)
        }
        
    }
    
    public class RapidGossipSyncTester {
        public func testRapidGossipSync() async throws {
            // first, download the gossip data
            print("Sending rapid gossip sync request…")
            var request = URLRequest(url: URL(string: "https://rapidsync.lightningdevkit.org/snapshot/0")!)
            request.httpMethod = "GET"
            
            let startA = DispatchTime.now()
            
            // DOWNLOAD DATA
            let (data, _) = try await URLSession.shared.data(for: request)
            
            let finishA = DispatchTime.now()
            let elapsedA = Double(finishA.uptimeNanoseconds-startA.uptimeNanoseconds)/1_000_000_000
            print("Received rapid gossip sync response: \(data.count) bytes! Time: \(elapsedA)s")
            
            let reversedGenesisHashHex = "6fe28c0ab6f1b372c1a6a246ae63f74f931e8365e15a089c68d6190000000000"
            let reversedGenesisHash = PlaynetLDKIntergrationSample.hexStringToBytes(hexString: reversedGenesisHashHex)!
            
            let logger = LDKTraitImplementations.PlaynetLogger()
            let networkGraph = NetworkGraph(network: .Regtest, logger: logger)
            let rapidSync = RapidGossipSync(networkGraph: networkGraph, logger: logger)
            
            let gossipDataRaw = [UInt8](data)
            print("Applying rapid sync data…")
            let startB = DispatchTime.now()
            
            // APPLY DATA
            let timestamp = rapidSync.updateNetworkGraph(updateData: gossipDataRaw)
            
            if let error = timestamp.getError() {
                print("error! type: \(error.getValueType())")
                let specificError = error.getValueAsLightningError()
                print("details: \(String(describing: specificError?.getErr()))")
            }
            let finishB = DispatchTime.now()
            let elapsedB = Double(finishB.uptimeNanoseconds-startB.uptimeNanoseconds)/1_000_000_000
            print("Applied rapid sync data: \(String(describing: timestamp.getValue()))! Time: \(elapsedB)s")
            
            print("Measuring graph size…")
            let startC = DispatchTime.now()
            let graphBytes = networkGraph.write()
            let finishC = DispatchTime.now()
            let elapsedC = Double(finishC.uptimeNanoseconds-startC.uptimeNanoseconds)/1_000_000_000
            print("Network graph size: \(graphBytes.count)! Time: \(elapsedC)s")
            
            
            // networkGraph.read_only().get_addresses(pubkey: <#T##[UInt8]#>)
            
            let scoringParams = ProbabilisticScoringParameters.initWithDefault()
            let scorer = ProbabilisticScorer(params: scoringParams, networkGraph: networkGraph, logger: logger)
            let score = scorer.asScore()
            // let multiThreadedScorer = MultiThreadedLockableScore(score: score)
            
            
            let payerPubkey = hexStringToBytes(hexString: "0242a4ae0c5bef18048fbecf995094b74bfb0f7391418d71ed394784373f41e4f3")!
            let recipientPubkey = hexStringToBytes(hexString: "03864ef025fde8fb587d989186ce6a4a186895ee44a926bfc370e2c366597a3f8f")!
            
//            let paymentParameters = PaymentParameters(payeePubkeyArg: recipientPubkey)
//            let routeParameters = RouteParameters(paymentParamsArg: paymentParameters, finalValueMsatArg: 500)
            
            print("STEP A")
            
//            let firstHops: [ChannelDetails]? = nil
//            print("STEP B")
//            let foundRoute = router.find_route(payer: payerPubkey, route_params: routeParameters, payment_hash: nil, first_hops: firstHops, scorer: score)
//            print("found route: \(foundRoute)")
        }
    }

    private class func bytesToHexString(bytes: [UInt8]) -> String {
        let format = "%02hhx" // "%02hhX" (uppercase)
        return bytes.map {
            String(format: format, $0)
        }
        .joined()
    }

    private class func hexStringToBytes(hexString: String) -> [UInt8]? {
        let hexStr = hexString.dropFirst(hexString.hasPrefix("0x") ? 2 : 0)

        guard hexStr.count % 2 == 0 else {
            return nil
        }

        var newData = [UInt8]()

        var indexIsEven = true
        for i in hexStr.indices {
            if indexIsEven {
                let byteRange = i...hexStr.index(after: i)
                guard let byte = UInt8(hexStr[byteRange], radix: 16) else {
                    return nil
                }
                newData.append(byte)
            }
            indexIsEven.toggle()
        }
        return newData
    }
}

class LDKTraitImplementations {

    class PlaynetFeeEstimator: FeeEstimator {
        override func getEstSatPer1000Weight(confirmationTarget: Bindings.ConfirmationTarget) -> UInt32 {
            return 253
        }
    }

    class PlaynetBroadcaster: BroadcasterInterface {

        private let rpcInterface: BlockchainObserver

        init(rpcInterface: BlockchainObserver) {
            self.rpcInterface = rpcInterface
            super.init()
        }

        override func broadcastTransaction(tx: [UInt8]) {
            Task {
                try? await self.rpcInterface.submitTransaction(transaction: tx)
            }
        }
    }
    
    class MuteBroadcaster: BroadcasterInterface {
        override func broadcastTransaction(tx: [UInt8]) {
            // do nothing
        }
    }

    class PlaynetLogger: Logger {
        override func log(record: Bindings.Record) {
            print("\nRLPlaynetLog (\(record.getLevel())): \(record.getFile()):\(record.getLine()):\n> \(record.getArgs())\n")
        }
    }
    
    class MuteLogger: Logger {
        override func log(record: Bindings.Record) {
            // do nothing
        }
    }

    class PlaynetChannelMonitorPersister: Persist {
        override func persistNewChannel(channelId: OutPoint, data: ChannelMonitor, updateId: MonitorUpdateId) -> Bindings.ChannelMonitorUpdateStatus {
            let _: [UInt8] = channelId.write()
            let _: [UInt8] = data.write()
            return .Completed
        }

        override func updatePersistedChannel(channelId: OutPoint, update: ChannelMonitorUpdate, data: ChannelMonitor, updateId updateIId: MonitorUpdateId) -> Bindings.ChannelMonitorUpdateStatus {
            let _: [UInt8] = channelId.write()
            let _: [UInt8] = data.write()
            return .Completed
        }
    }

    class PlaynetChannelManagerAndNetworkGraphPersisterAndEventHandler: Persister, ExtendedChannelManagerPersister {
        private let eventTracker = PendingEventTracker()

        fileprivate func getManagerEvents(expectedCount: UInt) async -> [Event] {
            while true {
                if await self.eventTracker.getCount() >= expectedCount {
                    return await self.eventTracker.getAndClearEvents()
                }
                await self.eventTracker.awaitAddition()
            }
        }

        func handleEvent(event: Event) {
            Task {
                await self.eventTracker.addEvent(event: event)
            }
        }

        override func persistManager(channelManager: Bindings.ChannelManager) -> Bindings.Result_NoneErrorZ {
            return Result_NoneErrorZ.initWithOk()
        }

        override func persistGraph(networkGraph: Bindings.NetworkGraph) -> Bindings.Result_NoneErrorZ {
            return Result_NoneErrorZ.initWithOk()
        }
        
        override func persistScorer(scorer: LightningDevKit.Bindings.WriteableScore) -> LightningDevKit.Bindings.Result_NoneErrorZ {
            return Result_NoneErrorZ.initWithOk()
        }

        fileprivate actor PendingEventTracker {

            private(set) var pendingEvents: [Event] = []
            private(set) var continuations: [CheckedContinuation<Void, Never>] = []

            private func triggerContinuations() {
                let continuations = self.continuations
                self.continuations.removeAll()
                for currentContinuation in continuations {
                    currentContinuation.resume()
                }
            }

            func addEvent(event: Event) {
                self.pendingEvents.append(event)
                self.triggerContinuations()
            }

            func addEvents(events: [Event]) {
                self.pendingEvents.append(contentsOf: events)
                self.triggerContinuations()
            }

            func getCount() -> Int {
                return self.pendingEvents.count
            }

            private func getEvents() -> [Event] {
                return self.pendingEvents
            }

            func getAndClearEvents() -> [Event] {
                let events = self.pendingEvents
                self.pendingEvents.removeAll()
                return events
            }

            func awaitAddition() async {
                await withCheckedContinuation({ continuation in
                    self.continuations.append(continuation)
                })
            }
        }

    }

}

struct Listener: BlockchainListener {
    private let channelManager: ChannelManager
    private let chainMonitor: ChainMonitor

    init(channelManager: ChannelManager, chainMonitor: ChainMonitor) {
        self.channelManager = channelManager
        self.chainMonitor = chainMonitor
    }

    func blockConnected(block: [UInt8], height: UInt32) {
        self.channelManager.asListen().blockConnected(block: block, height: height)
        self.chainMonitor.asListen().blockConnected(block: block, height: height)
    }

    func blockDisconnected(header: [UInt8]?, height: UInt32) {
        self.chainMonitor.asListen().blockDisconnected(header: header, height: height)
        self.channelManager.asListen().blockDisconnected(header: header, height: height)
    }
}

import Foundation

/// A class that's supposed to help monitoring a regtest blockchain data using the bitcoin RPC interface.
///
@available(iOS 15.0, *)
class RegtestBlockchainManager: BlockchainObserver {

    /**
     Mine regtest blocks
     - Parameters:
       - number: The number of blocks to mine
       - coinbaseDestinationAddress: The output address to be used in the coinbase transaction(s)
     - Returns: Array of the mined blocks' hashes
     - Throws: If the RPC connection fails or the call results in an error
     */
    public func mineBlocks(number: Int64, coinbaseDestinationAddress: String) async throws -> [String] {
        let response = try await self.callRpcMethod(method: "generatetoaddress", params: [
            "nblocks": number,
            "address": coinbaseDestinationAddress
        ] as [String : Any])
        let result = response["result"] as! [String]
        return result
    }

    /**
     Invalidate or un-mine a block
     - Parameter hash: The block hash hex to invalidate
     - Returns:
     - Throws:
     */
    public func unmineBlock(hash: String) async throws {
        let response = try await self.callRpcMethod(method: "invalidateblock", params: [hash])
    }

}

import Combine

@available(iOS 15.0, *)
class BlockchainObserver {

    public enum InitError: Error {
        case invalidUrlString
    }

    public enum RpcError: Error {
        case errorResponse(RPCErrorDetails)
    }

    public enum ObservationError: Error {
        case alreadyInProgress
        case nonSequentialBlockConnection
        case unhandledReorganization
        case excessiveReorganization
    }

    /**
     Which block height should the monitor start from?
     */
    public enum MonitorAnchor {
        /**
         Start from the genesis block, and catch up on all data thence
         */
        case genesis
        /**
         Start from a specific block height, and catch up through the chaintip
         */
        case block(Int64)
        /**
         Start from the chaintip, and only register new blocks as they come
         */
        case chaintip
    }

    public enum RpcProtocol {
        case http
        case https

        func toString() -> String {
            switch self {
            case .http:
                return "http"
            case .https:
                return "https"
            }
        }

        func defaultPort() -> UInt {
            switch self {
            case .http:
                return 80
            case .https:
                return 443
            }
        }
    }

    struct RPCErrorDetails {
        let message: String
        let code: Int64
    }

    struct RPCBlockDetails: Codable {
        let hash: String
        let version: Int64
        let mediantime: Int64
        let nonce: Int64
        let chainwork: String
        let nTx: Int64
        let time: Int64
        let weight: Int64
        let merkleroot: String
        let size: Int64
        let confirmations: Int64
        let versionHex: String
        let height: Int64
        let difficulty: Double
        let strippedsize: Int64
        let previousblockhash: String?
        let bits: String
        let tx: [String]
    }

    private let rpcProtocol: RpcProtocol
    private let rpcDomain: String
    private let rpcPort: UInt
    private let rpcUsername: String
    private let rpcPassword: String

    private actor MonitoringTracker {
        private(set) var isPreloaded = false
        private(set) var isTracking = false

        fileprivate func preload() -> Bool {
            let wasPreloaded = self.isPreloaded
            self.isPreloaded = true
            return wasPreloaded
        }

        fileprivate func startTracking() -> Bool {
            let wasTracking = self.isTracking
            self.isTracking = true
            return wasTracking
        }
    }

    private let monitoringTracker = MonitoringTracker()
    private var anchorBlock: RPCBlockDetails?
    private var connectedBlocks = [RPCBlockDetails]()

    private var chainListeners = [BlockchainListener]()

    public init(rpcProtocol: RpcProtocol, rpcDomain: String, rpcPort: UInt?, rpcUsername: String, rpcPassword: String) throws {
        self.rpcProtocol = rpcProtocol
        self.rpcDomain = rpcDomain
        self.rpcPort = rpcPort ?? rpcProtocol.defaultPort()
        self.rpcUsername = rpcUsername
        self.rpcPassword = rpcPassword
        guard self.getRpcEndpoint() != nil else {
            throw InitError.invalidUrlString
        }
    }

    public func registerListener(_ listener: BlockchainListener) {
        self.chainListeners.append(listener)
    }

    public func preloadMonitor(anchorHeight: MonitorAnchor = .genesis) async throws {
        let isPreloaded = await self.monitoringTracker.preload()
        if isPreloaded {
            // no need to preload twice
            return
        }
        var lastTrustedBlockHeight: Int64
        let chaintipHeight = try await self.getChaintipHeight()
        switch anchorHeight {
        case .genesis:
            lastTrustedBlockHeight = 0
        case .block(let height):
            lastTrustedBlockHeight = height
        case .chaintip:
            lastTrustedBlockHeight = chaintipHeight
        }

        let anchorBlockHash = try await self.getBlockHashHex(height: lastTrustedBlockHeight)
        self.anchorBlock = try await self.getBlock(hash: anchorBlockHash)
        self.connectedBlocks.append(self.anchorBlock!)

        if lastTrustedBlockHeight != chaintipHeight {
            // gotta connect blocks all the way to the chain tip
            for currentBlockHeight in (lastTrustedBlockHeight + 1)...chaintipHeight {
                let currentBlockHash = try await self.getBlockHashHex(height: currentBlockHeight)
                let currentBlock = try await self.getBlock(hash: currentBlockHash)
                try await self.connectBlock(block: currentBlock)
            }
        }

    }

    public func monitorBlockchain() async throws {
        try await preloadMonitor()
        let isMonitoring = await self.monitoringTracker.startTracking()
        if isMonitoring {
            throw ObservationError.alreadyInProgress
        }
        while true {
            try await reconcileChaintips()
            // sleep for 5s
            try await Task.sleep(nanoseconds: 5_000_000_000)
        }
    }

    // Manually trigger a check of what's the latest
    public func reconcileChaintips() async throws {
        let currentChaintipHeight = try await self.getChaintipHeight()
        let currentChaintipHash = try await self.getChaintipHashHex()
        let knownChaintip = self.connectedBlocks.last!
        if knownChaintip.height == currentChaintipHeight && knownChaintip.hash == currentChaintipHash {
            // we're still at chaintip
            return
        }

        // create an array of the new blocks
        var addedBlocks = [RPCBlockDetails]()
        if knownChaintip.height < currentChaintipHeight {
            // without this precondition, the range won't even work to begin with
            for addedBlockHeight in (knownChaintip.height + 1)...currentChaintipHeight {
                let addedBlockHash = try await self.getBlockHashHex(height: addedBlockHeight)
                let addedBlock = try await self.getBlock(hash: addedBlockHash)
                addedBlocks.append(addedBlock)
            }
        }

        while addedBlocks.isEmpty || addedBlocks.first!.previousblockhash != self.connectedBlocks.last!.hash {
            // we must keep popping until it matches
            let trimmingCandidate = self.connectedBlocks.last!
            if trimmingCandidate.height > currentChaintipHeight {
                // we can disconnect this block without prejudice
                let _ = try await self.disconnectBlock()
                continue
            }
            let reorgedBlockHash = try await self.getBlockHashHex(height: trimmingCandidate.height)
            if reorgedBlockHash == trimmingCandidate.hash {
                // this block matches the one we already have
                break
            }
            let reorgedBlock = try await self.getBlock(hash: reorgedBlockHash)
            let _ = try await self.disconnectBlock()
            addedBlocks.insert(reorgedBlock, at: 0)
        }

        for addedBlock in addedBlocks {
            try await self.connectBlock(block: addedBlock)
        }

    }

    private func disconnectBlock() async throws -> RPCBlockDetails {
        if self.connectedBlocks.count <= 1 {
            // we're about to disconnect the anchor block, which we can't
            throw ObservationError.excessiveReorganization
        }

        let poppedBlock = self.connectedBlocks.popLast()!

        print("disconnecting block \(poppedBlock.height) with hex: \(poppedBlock.hash)")

        if self.chainListeners.count > 0 {
            let blockHeader = try await self.getBlockHeader(hash: poppedBlock.hash)
            for listener in self.chainListeners {
                listener.blockDisconnected(header: blockHeader, height: UInt32(poppedBlock.height))
            }
        }

        return poppedBlock
    }

    private func connectBlock(block: RPCBlockDetails) async throws {
        if self.connectedBlocks.count > 0 {
            let lastConnectionHeight = self.connectedBlocks.last!.height
            if lastConnectionHeight + 1 != block.height {
                // trying to connect block out of order
                throw ObservationError.nonSequentialBlockConnection
            }
            let lastBlockHash = self.connectedBlocks.last!.hash
            if block.previousblockhash != lastBlockHash {
                // this should in principle never occur, as the caller should check and reconcile beforehand
                throw ObservationError.unhandledReorganization
            }
        }

        print("connecting block    \(block.height) with hex: \(block.hash)")

        if self.chainListeners.count > 0 {
            let binary = try await self.getBlockBinary(hash: block.hash)
            for listener in self.chainListeners {
                listener.blockConnected(block: binary, height: UInt32(block.height))
            }
        }

        self.connectedBlocks.append(block)
    }

    private func getRpcEndpoint() -> URL? {
        let urlString = "\(self.rpcProtocol)://\(self.rpcUsername):\(self.rpcPassword)@\(self.rpcDomain):\(self.rpcPort)"
        return URL(string: urlString)
    }

    internal func callRpcMethod(method: String, params: Any) async throws -> [String: Any] {
        let url = self.getRpcEndpoint()!
        let body: [String: Any] = [
            "method": method,
            "params": params
        ]
        let jsonBody = try JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonBody
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONSerialization.jsonObject(with: data, options: .topLevelDictionaryAssumed)
        // print("JSON-RPC response: \(response)")
        let responseDictionary = response as! [String: Any]
        if let responseError = responseDictionary["error"] as? [String: Any] {
            let errorDetails = RPCErrorDetails(message: responseError["message"] as! String, code: responseError["code"] as! Int64)
            print("rpc error details: \(errorDetails)")
            throw RpcError.errorResponse(errorDetails)
        }
        return responseDictionary
    }

    public func getHelp(command: String? = nil) async throws -> String {
        var params = [String]()
        if let command = command {
            params.append(command)
        }
        let response = try await self.callRpcMethod(method: "help", params: params)
        let result = response["result"] as! String
        return result
    }

    public func getChaintipHeight() async throws -> Int64 {
        let response = try await self.callRpcMethod(method: "getblockcount", params: [])
        let result = response["result"] as! Int64
        return result
    }

    public func getChaintipHashHex() async throws -> String {
        let chainInfo = try await self.getChainInfo()
        return chainInfo["bestblockhash"] as! String
    }

    public func getChaintipHash() async throws -> [UInt8] {
        let blockHashHex = try await self.getChaintipHashHex()
        return hexStringToBytes(hexString: blockHashHex)!
    }

    public func getBlockHashHex(height: Int64) async throws -> String {
        let response = try await self.callRpcMethod(method: "getblockhash", params: ["height": height])
        let result = response["result"] as! String
        return result
    }

    public func getBlockHash(height: Int64) async throws -> [UInt8] {
        let blockHashHex = try await self.getBlockHashHex(height: height)
        return hexStringToBytes(hexString: blockHashHex)!
    }

    public func getBlock(hash: String) async throws -> RPCBlockDetails {
        let response = try await self.callRpcMethod(method: "getblock", params: [hash])
        let result = response["result"] as! [String: Any]
        let blockDetails = try JSONDecoder().decode(RPCBlockDetails.self, from: JSONSerialization.data(withJSONObject: result))
        return blockDetails
    }

    public func getBlockBinary(hash: String) async throws -> [UInt8] {
        let response = try await self.callRpcMethod(method: "getblock", params: [hash, 0])
        let result = response["result"] as! String
        let blockData = hexStringToBytes(hexString: result)!
        return blockData
    }

    public func getBlockHeader(hash: String) async throws -> [UInt8] {
        let response = try await self.callRpcMethod(method: "getblockheader", params: [hash, false])
        let result = response["result"] as! String
        let blockHeader = hexStringToBytes(hexString: result)!
        assert(blockHeader.count == 80)
        return blockHeader
    }

    public func getTransaction(hash: String) async throws -> [UInt8] {
        let response = try await self.callRpcMethod(method: "getrawtransaction", params: [hash])
        let txHex = response["result"] as! String
        let transaction = hexStringToBytes(hexString: txHex)!
        return transaction
    }

    /**
     Get chain details such as the chaintip hash, the active soft forks, etc.
     - Returns:
     - Throws:
     */
    public func getChainInfo() async throws -> [String: Any] {
        let response = try await self.callRpcMethod(method: "getblockchaininfo", params: [])
        let result = response["result"] as! [String: Any]
        return result
    }

    /**
     Generate a new address in the active wallet
     - Returns: Address string
     - Throws:
     */
    public func generateAddress() async throws -> String {
        let response = try await self.callRpcMethod(method: "getnewaddress", params: [])
        let result = response["result"] as! String
        return result
    }

    /**
     Submit a serialized transaction for broadcasting
     - Parameter transaction: byte array serialization of transaction
     - Returns: Transaction id string
     - Throws:
     */
    public func submitTransaction(transaction: [UInt8]) async throws -> String {
        let txHex = bytesToHexString(bytes: transaction)
        let response = try await self.callRpcMethod(method: "sendrawtransaction", params: [txHex])
        // returns the txid
        let result = response["result"] as! String
        return result
    }

    /**
     Send money to an address
     - Parameters:
       - destinationAddress: Address to send the bitcoin to
       - amount: Amount to send in BTC
     - Throws:
     */
    public func sendPayment(destinationAddress: String, amount: String) async throws -> String {
        let response = try await self.callRpcMethod(method: "sendtoaddress", params: [destinationAddress, amount])
        let result = response["result"] as! String
        return result
    }

    /**
     Decode an arbitary script. Can be an output script, a redeem script, or anything else
     - Parameter script: byte array serialization of script
     - Returns: Object with various possible interpretations of the script
     - Throws:
     */
    public func decodeScript(script: [UInt8]) async throws -> [String: Any] {
        let scriptHex = bytesToHexString(bytes: script)
        let response = try await self.callRpcMethod(method: "decodescript", params: [scriptHex])
        let result = response["result"] as! [String: Any]
        return result
    }

    // wallet stuff

    public func getWalletInfo() async throws -> [String: Any] {
        let response = try await self.callRpcMethod(method: "getwalletinfo", params: [])
        let result = response["result"] as! [String: Any]
        return result
    }

    /**
     Get balance of the currently loaded wallet
     - Returns: Spendable balance in BTC
     - Throws: When multiple wallets are loaded
     */
    public func getWalletBalance() async throws -> Double {
        let response = try await self.callRpcMethod(method: "getbalance", params: [])
        let result = response["result"] as! Double
        return result
    }

    public func listAvailableWallets() async throws -> [String: Any] {
        let response = try await self.callRpcMethod(method: "listwalletdir", params: [])
        let result = response["result"] as! [String: Any]
        return result
    }

    public func listLoadedWallets() async throws -> [String] {
        let response = try await self.callRpcMethod(method: "listwallets", params: [])
        let result = response["result"] as! [String]
        return result
    }

    public func createWallet(name: String) async throws -> [String: Any] {
        let response = try await self.callRpcMethod(method: "createwallet", params: [name])
        let result = response["result"] as! [String: Any]
        return result
    }

    public func loadWallet(name: String) async throws -> [String: Any] {
        let response = try await self.callRpcMethod(method: "loadwallet", params: [name])
        let result = response["result"] as! [String: Any]
        return result
    }

    public func unloadWallet(name: String) async throws -> [String: Any] {
        let response = try await self.callRpcMethod(method: "unloadwallet", params: [name])
        let result = response["result"] as! [String: Any]
        return result
    }

    public func isMonitoring() async throws -> Bool {
        await monitoringTracker.isTracking
    }
    
    public var blockchainMonitorPublisher: AnyPublisher<Void, Error> {
        Timer.publish(every: 5.0, on: RunLoop.main, in: .default)
            .autoconnect()
            .asyncMap { [unowned self] _ in
                try await self.reconcileChaintips()
            }
            .eraseToAnyPublisher()
    }
}

import Combine

extension Publisher {
    func asyncMap<T>(
        _ transform: @escaping (Output) async throws -> T
    ) -> Publishers.FlatMap<Combine.Future<T, Error>,
                            Publishers.SetFailureType<Self, Error>> {
        flatMap { value in
            Future { promise in
                Task {
                    do {
                        let output = try await transform(value)
                        promise(.success(output))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
    }
}

public protocol BlockchainListener {
    func blockConnected(block: [UInt8], height: UInt32)
    func blockDisconnected(header: [UInt8]?, height: UInt32)
}

fileprivate func hexStringToBytes(hexString: String) -> [UInt8]? {
    let hexStr = hexString.dropFirst(hexString.hasPrefix("0x") ? 2 : 0)

    guard hexStr.count % 2 == 0 else {
        return nil
    }

    var newData = [UInt8]()

    var indexIsEven = true
    for i in hexStr.indices {
        if indexIsEven {
            let byteRange = i...hexStr.index(after: i)
            guard let byte = UInt8(hexStr[byteRange], radix: 16) else {
                return nil
            }
            newData.append(byte)
        }
        indexIsEven.toggle()
    }
    return newData
}

fileprivate func bytesToHexString(bytes: [UInt8]) -> String {
    let format = "%02hhx" // "%02hhX" (uppercase)
    return bytes.map {
        String(format: format, $0)
    }
    .joined()
}
