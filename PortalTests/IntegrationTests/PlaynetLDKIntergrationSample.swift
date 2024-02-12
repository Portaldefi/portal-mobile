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
        let logger = LDKTraitImplementations.PlaynetLogger(id: "PlaynetLDKIntergrationSample", logLevels: [.Info, .Warn, .Error])

        let config = UserConfig.initWithDefault()
        let lightningNetwork: Network = .Regtest
        let genesisHash = try await rpcInterface.getBlockHash(height: 0)
        let reversedGenesisHash = [UInt8](genesisHash.reversed())
        let chaintipHash = try await rpcInterface.getChaintipHash()
        let reversedChaintipHash = [UInt8](chaintipHash.reversed())
        let chaintipHeight = try await rpcInterface.getChaintipHeight()
        let networkGraph = NetworkGraph(network: .Regtest, logger: logger)

        let probabalisticScorer = ProbabilisticScorer(decayParams: .initWithDefault(), networkGraph: networkGraph, logger: logger)
        let score = probabalisticScorer.asScore()
        let multiThreadedScorer = MultiThreadedLockableScore(score: score)

        print("Genesis hash: \(Utils.bytesToHexString(bytes: genesisHash))")
        print("Genesis hash reversed: \(Utils.bytesToHexString(bytes: reversedGenesisHash))")
        print("Block 1 hash: \(try await rpcInterface.getBlockHashHex(height: 1))")
        print("Block 2 hash: \(try await rpcInterface.getBlockHashHex(height: 2))")
        print("Chaintip hash: \(Utils.bytesToHexString(bytes: chaintipHash))")
        print("Chaintip hash reversed: \(Utils.bytesToHexString(bytes: reversedChaintipHash))")

        let feeEstimator = LDKTraitImplementations.PlaynetFeeEstimator()
        let broadcaster = LDKTraitImplementations.PlaynetBroadcaster(rpcInterface: rpcInterface)
        
        let channelMonitorPersister = LDKTraitImplementations.PlaynetChannelMonitorPersister()
        let channelManagerAndNetworkGraphPersisterAndEventHandler = LDKTraitImplementations.PlaynetChannelManagerAndNetworkGraphPersisterAndEventHandler(id: "Playnet integration sample")
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

        let listener = LDKTraitImplementations.Listener(channelManager: channelManager, chainMonitor: chainMonitor)
        rpcInterface.registerListener(listener)
        async let _: () = try rpcInterface.monitorBlockchain()
        channelManagerConstructor.chainSyncCompleted(persister: channelManagerAndNetworkGraphPersisterAndEventHandler)

        guard let lndPubkey = Utils.hexStringToBytes(hexString: PlaynetLDKIntergrationSample.PLAYNET_ALICE_PEER_PUBKEY_HEX) else {
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
        
        let invoiceResult = Bolt11Invoice.fromStr(s: PlaynetLDKIntergrationSample.PLAYNET_ALICE_PEER_INVOICE)

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
            print("sent payment \(String(describing: paymentSent.getPaymentId()?.toHexString())) with fee \(String(describing: paymentSent.getFeePaidMsat())) via \(paymentPathSuccessful.getPath())")
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
            let reversedGenesisHash = Utils.hexStringToBytes(hexString: reversedGenesisHashHex)!
            let chaintipHeight = 0
            let reversedChaintipHash = reversedGenesisHash
            networkGraph = NetworkGraph(network: .Regtest, logger: logger)
            
            print("Genesis hash reversed: \(Utils.bytesToHexString(bytes: reversedGenesisHash))")

            let probabalisticScorer = ProbabilisticScorer(decayParams: .initWithDefault(), networkGraph: networkGraph, logger: logger)
            let score = probabalisticScorer.asScore()
            multiThreadedScorer = MultiThreadedLockableScore(score: score)
            
            feeEstimator = LDKTraitImplementations.PlaynetFeeEstimator()
            broadcaster = LDKTraitImplementations.MuteBroadcaster()
            
            let channelMonitorPersister = LDKTraitImplementations.PlaynetChannelMonitorPersister()
            let channelManagerAndNetworkGraphPersisterAndEventHandler = LDKTraitImplementations.PlaynetChannelManagerAndNetworkGraphPersisterAndEventHandler(id: "Playnet integration sample")
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
                let connectionResult = tcpPeerHandler.connect(address: "52.50.244.44", port: 9735, theirNodeId: Utils.hexStringToBytes(hexString: "030c3f19d742ca294a55c00376b3b355c3c90d61c6b6b39554dbc7ac19b141c14f")!)
                print("bitrefill connection success: \(connectionResult)")
                await pauseForNextPeer()
            }
            
            do {
                // River
                print("connecting river")
                let connectionResult = tcpPeerHandler.connect(address: "104.196.249.140", port: 9735, theirNodeId: Utils.hexStringToBytes(hexString: "03037dc08e9ac63b82581f79b662a4d0ceca8a8ca162b1af3551595b8f2d97b70a")!)
                print("river connection success: \(connectionResult)")
                await pauseForNextPeer()
            }
            
            do {
                // Acinq
                print("connecting acinq")
                let connectionResult = tcpPeerHandler.connect(address: "3.33.236.230", port: 9735, theirNodeId: Utils.hexStringToBytes(hexString: "03864ef025fde8fb587d989186ce6a4a186895ee44a926bfc370e2c366597a3f8f")!)
                print("acinq connection success: \(connectionResult)")
                await pauseForNextPeer()
            }
            
            do {
                // Kraken
                print("connecting kraken")
                let connectionResult = tcpPeerHandler.connect(address: "52.13.118.208", port: 9735, theirNodeId: Utils.hexStringToBytes(hexString: "02f1a8c87607f415c8f22c00593002775941dea48869ce23096af27b0cfdcc0b69")!)
                print("kraken connection success: \(connectionResult)")
                await pauseForNextPeer()
            }
            
            do {
                // Matt
                print("connecting matt")
                let connectionResult = tcpPeerHandler.connect(address: "69.59.18.80", port: 9735, theirNodeId: Utils.hexStringToBytes(hexString: "03db10aa09ff04d3568b0621750794063df401e6853c79a21a83e1a3f3b5bfb0c8")!)
                print("matt connection success: \(connectionResult)")
                await pauseForNextPeer()
            }
            
            do {
                // Fold
                print("connecting fold")
                let connectionResult = tcpPeerHandler.connect(address: "35.238.153.25", port: 9735, theirNodeId: Utils.hexStringToBytes(hexString: "02816caed43171d3c9854e3b0ab2cf0c42be086ff1bd4005acc2a5f7db70d83774")!)
                print("fold connection success: \(connectionResult)")
                await pauseForNextPeer()
            }
            
            do {
                // wallet of satoshi
                print("connecting wallet of satoshi")
                let connectionResult = tcpPeerHandler.connect(address: "170.75.163.209", port: 9735, theirNodeId: Utils.hexStringToBytes(hexString: "035e4ff418fc8b5554c5d9eea66396c227bd429a3251c8cbc711002ba215bfc226")!)
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
            let reversedGenesisHash = Utils.hexStringToBytes(hexString: reversedGenesisHashHex)!
            
            let logger = LDKTraitImplementations.PlaynetLogger(id: "RapidGossipSyncTester", logLevels: [.Info, .Warn, .Debug])
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
            
            let scorer = ProbabilisticScorer(decayParams: .initWithDefault(), networkGraph: networkGraph, logger: logger)
            let score = scorer.asScore()
            // let multiThreadedScorer = MultiThreadedLockableScore(score: score)
            
            
            let payerPubkey = Utils.hexStringToBytes(hexString: "0242a4ae0c5bef18048fbecf995094b74bfb0f7391418d71ed394784373f41e4f3")!
            let recipientPubkey = Utils.hexStringToBytes(hexString: "03864ef025fde8fb587d989186ce6a4a186895ee44a926bfc370e2c366597a3f8f")!
            
//            let paymentParameters = PaymentParameters(payeePubkeyArg: recipientPubkey)
//            let routeParameters = RouteParameters(paymentParamsArg: paymentParameters, finalValueMsatArg: 500)
            
            print("STEP A")
            
//            let firstHops: [ChannelDetails]? = nil
//            print("STEP B")
//            let foundRoute = router.find_route(payer: payerPubkey, route_params: routeParameters, payment_hash: nil, first_hops: firstHops, scorer: score)
//            print("found route: \(foundRoute)")
        }
    }
}

import Foundation

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
