//
//  Node.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation
import Combine
import LightningDevKit

extension Bool {
    var string: String {
        self ? "yes" : "no"
    }
}

extension StringProtocol {
    var hexaData: Data { .init(hexa) }
    var hexaBytes: [UInt8] { .init(hexa) }
    private var hexa: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            guard startIndex < endIndex else { return nil }
            let endIndex = index(startIndex, offsetBy: 2, limitedBy: endIndex) ?? endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}

public class Node {
    let fileManager = LightningFileManager()
    let pendingEventTracker = PendingEventTracker()
    let connectionType: ConnectionType
    
    var keysManager: KeysManager?
    var rpcInterface: RpcChainManager?
    var broadcaster: Broadcaster?
    var channelManagerConstructor: ChannelManagerConstructor?
    var channelManager: ChannelManager?
    var persister: Persister?
    var peerManager: PeerManager?
    var tcpPeerHandler: TCPPeerHandler?
        
    var cancellables = Set<AnyCancellable>()
        
    // We declare this here because `ChannelManagerConstructor` and `ChainMonitor` will share a reference to them
    let logger = Logger()
    let feeEstimator = FeeEstimator()
    let filter = Filter()
    
    // all user channels
    public var allChannels: [ChannelDetails] {
        channelManager?.listChannels() ?? []
    }
    // usable user channels
    public var usableChannels: [ChannelDetails] {
        channelManager?.listUsableChannels() ?? []
    }
    
    public var totalBalance: UInt64 {
        allChannels.map{ $0.getBalanceMsat() }.reduce(0){ $0 + $1 }
    }
    
    public init(type: ConnectionType) {
        self.connectionType = type
    }
    
    /// Start the Lightning node
    public func start() async throws {
        // (1) Retrieve our key's 32-byte seed
        guard let keySeed = fileManager.getKeysSeed() else { throw NodeError.keySeedNotFound }
        
//        Bindings.setLogThreshold(severity: .DEBUG)
        
        let timestampInSeconds = UInt64(Date().timeIntervalSince1970)
        let timestampInNanoseconds = UInt32(truncating: NSNumber(value: timestampInSeconds * 1000 * 1000))
        
        // (2) Setup KeysManager with `keySeed`. With add entropy using the current time. See this comment for more information: https://docs.rs/lightning/0.0.112/lightning/chain/keysinterface/struct.KeysManager.html#method.new
        keysManager = KeysManager(seed: keySeed, startingTimeSecs: timestampInSeconds, startingTimeNanos: timestampInNanoseconds)
        
        // (3) Grabs an instance of KeysInterface, we will need it later to construct a ChannelManager
        guard let keysInterface = keysManager else {
            throw NodeError.keyInterfaceFailure
        }
        
        // (4) Initialize rpcInterface, which represents a series of chain methods that are necessary for chain sync.
        // interact with different types of block sources with just a different choice of a `RpcChainManager` instance.
        switch connectionType {
        case .regtest(let config):
            let regtestBlockchainManager = try RegtestBlockchainManager(
                rpcProtocol: .http,
                host: config.host,
                port: config.port,
                username: "lnd",
                password: "lnd"
            )
            rpcInterface = regtestBlockchainManager
        case .testnet(let bitcoinTestNetConfig):
            switch bitcoinTestNetConfig {
            case .blockStream:
                rpcInterface = try BlockStreamChainManager(rpcProtocol: .https)
            }
        }
        
        guard let rpcInterface = rpcInterface else {
            throw NodeError.noRpcInterface
        }
        
        // (5) Initialized Broadcaster, primarily responsible for broadcasting requisite transaction on-chain.
        broadcaster = Broadcaster(rpcInterface: rpcInterface)
        
        // (6) Initialize a ChainMonitor. As the name describes, this is what we will use to watch on-chain activity
        // related to our channels.
        let chainMonitor = ChainMonitor(
            chainSource: filter,
            broadcaster: broadcaster!,
            logger: logger,
            feeest: feeEstimator,
            persister: ChannelPersister()
        )
        
        // (7) Read network graph and probalistic scorer from storage or create new object
        
        let networkGraph = initNetworkGraph()
        let probabalisticScorer = initProbabilisticScorer(networkGraph: networkGraph, logger: logger)
        let score = probabalisticScorer.asScore()
        let multiThreadedScorer = MultiThreadedLockableScore(score: score)
        let userConfig = UserConfig.initWithDefault()
        
        // ChannelManagerConstructionParameters
        
        let channelManagerConstructorParameters = ChannelManagerConstructionParameters(
            config: userConfig,
            entropySource: keysInterface.asEntropySource(),
            nodeSigner: keysInterface.asNodeSigner(),
            signerProvider: keysInterface.asSignerProvider(),
            feeEstimator: feeEstimator,
            chainMonitor: chainMonitor,
            txBroadcaster: broadcaster!,
            logger: logger,
            enableP2PGossip: true,
            scorer: multiThreadedScorer
        )
        
        // (8) Construct ChannelManager. The ChannelManager, as mentioned earlier, is like the brain of the node. It is responsible for
        // sending messages to appropriate channels, track HTLCs, forward onion packets, and also track a user's channels. It can also be
        // persisted on disk, which is what you generally want to do as often as possible -- this is equivalent to a "node backup".
        // The general advice here is to make sure that your `ChannelManager` *is encrypted*, because you can certainly glean information
        // about a user's payment history if they get leaked out in the clear.
        
        if fileManager.hasChannelMaterialAndNetworkGraph {
            // Load our channel manager from disk
            channelManagerConstructor = try await loadChannelManagerConstructor(params: channelManagerConstructorParameters)
        } else {
            // An existing ChannelManager does not exist on disk, create new channel material and network graph
            let chaintipHeight = try await rpcInterface.getChaintipHeight()
            let chaintipHash = try await rpcInterface.getChaintipHash()
            let reversedChaintipHash = [UInt8](chaintipHash.reversed())
                        
            channelManagerConstructor = try await initializeChannelMaterialAndNetworkGraph(
                currentTipHash: reversedChaintipHash,
                currentTipHeight: chaintipHeight,
                networkGraph: networkGraph,
                params: channelManagerConstructorParameters
            )
        }
        
        guard let channelManagerConstructor = channelManagerConstructor else {
            throw NodeError.noChannelManager
        }
        
        // Create shared instance reference to these objects, so we can use them for opening and managing channels and connecting to peers,
        // respectively.
        channelManager = channelManagerConstructor.channelManager
        
        guard let channelManager = channelManager else {
            throw NodeError.noChannelManager
        }
        
        peerManager = channelManagerConstructor.peerManager
        tcpPeerHandler = channelManagerConstructor.getTCPPeerHandler()
        
        let blockchainListener = ChainListener(channelManager: channelManager, chainMonitor: chainMonitor)
        rpcInterface.registerListener(blockchainListener)
                
        // (9) Do requisite chain sync to start.
        
        let bestBlockHeight = channelManager.currentBestBlock().height()
        
        if case .regtest = connectionType, let rpcInterface = rpcInterface as? RegtestBlockchainManager {
            // If we're using Bitcoin Core
            try await rpcInterface.preloadMonitor(anchorHeight: .block(bestBlockHeight))
        }
        
        if case .testnet = connectionType, let rpcInterface = rpcInterface as? BlockStreamChainManager {
            // If we're using BlockStream
            try await rpcInterface.preloadMonitor(anchorHeight: .block(bestBlockHeight))
        }
        
        // we will tell the ChainMonitor to connect blocks up to the latest chain tip.
        
        // (10) Initialize Persister, which is primarily responsible for persisting `ChannelManager`, `Scorer`, and `NetworkGraph` to disk.
        persister = Persister(eventTracker: pendingEventTracker)
        
        let isMonitoring = await rpcInterface.isMonitoring()

        if !isMonitoring {
            try subscribeToChainPublisher()
        } else {
            print("Monitor already running")
        }
     
        print("LDK is Running with key: \(channelManager.getOurNodeId().toHexString())")
    }
    
    //MARK: - Connect to peer
    public func connectPeer(pubKey: String, hostname: String, port: UInt16) async throws {
        print("Connecting to peer \(pubKey), host: \(hostname), port: \(port)")
        
        guard let _ = peerManager, let tcpPeerHandler = tcpPeerHandler else {
            throw NodeError.connectPeer
        }
        
        let start = DispatchTime.now()
        let connected = tcpPeerHandler.connect(address: hostname, port: port, theirNodeId: pubKey.toByteArray())
        let end = DispatchTime.now()
        
        if !connected {
            print("failed to connect")
        } else {
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanoTime)/1_000_000_000
            print("Peer \(pubKey) connected in \(timeInterval) seconds")
        }
    }
    //MARK: - Disconnect from peer
    public func disconnectPeer(pubKey: String) throws {
        print("Connecting to peer \(pubKey)")
        
        guard let peerManager = peerManager else {
            throw NodeError.disconectPeer
        }
        
        peerManager.disconnectByNodeId(nodeId: pubKey.toByteArray())
    }
    
    //MARK: - Open channel request
    public func requestChannelOpen(_ pubKeyHex: String, channelValue: UInt64, reserveAmount: UInt64) async throws -> ChannelOpenInfo {
        guard let channelManager = channelManager else {
            throw NodeError.Channels.channelManagerNotFound
        }
        
        // open_channel
        let theirNodeId = pubKeyHex.toByteArray()
        let config = UserConfig.initWithDefault()
        
        let userChannelId: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...UInt8.max) } //[UInt8](repeating: 42, count: 16)//
        
        print("user channel id \(userChannelId.toHexString())")

        let channelOpenResult = channelManager.createChannel(
            theirNetworkKey: theirNodeId,
            channelValueSatoshis: channelValue,
            pushMsat: reserveAmount,
            userChannelId: userChannelId,
            overrideConfig: config
        )
        
        // See if peer has returned `accept_channel`
        if channelOpenResult.isOk() {
            guard let event = await pendingEventTracker.await(events: [.fundingGenerationReady, .channelClosed], timeout: 3) else {
                throw NodeError.error("Not received funding or close event. Timeout error")
            }
            
            switch event.getValueType() {
            case .FundingGenerationReady:
                guard let fundingReadyEvent = event.getValueAsFundingGenerationReady() else {
                    throw NodeError.error("getValueAsFundingGenerationReady is nil")
                }

                return ChannelOpenInfo(
                    fundingEvent: fundingReadyEvent,
                    counterpartyNodeId: theirNodeId
                )
            case .ChannelClosed:
                guard let channelClosedEvent = event.getValueAsChannelClosed() else {
                    throw NodeError.error("getValueAsChannelClosed is nil")
                }
                
                let reason = channelClosedEvent.getReason()
                
                if let _ = reason.getValueAsCounterpartyForceClosed() {
                    throw NodeError.Channels.forceClosed
                } else if let _ = reason.getValueAsProcessingError() {
                    throw NodeError.Channels.closedWithError
                } else {
                    throw NodeError.Channels.unknown
                }
            default:
                print(event.getValueType())
                throw NodeError.Channels.wrongLDKEvent
            }
        } else if let errorDetails = channelOpenResult.getError() {
            throw errorDetails.getLDKError()
        }
        
        throw NodeError.Channels.unknown
    }
    
//    public func getFundingTransaction(fundingTxid: String) async -> [UInt8] {
//        // FIXME: We can probably not force unwrap here if we can carefully intialize rpcInterface in the Node's initializer
//        return try! await rpcInterface!.getTransaction(with: fundingTxid)
//    }
    
    //MARK: - Finishing Open channel
    // You will need channelOpenInfo from `requestChannelOpen`, and `fundingTransaction` from `getFundingTransaction`
    public func openChannel(channelOpenInfo: ChannelOpenInfo, fundingTransaction: [UInt8]) async throws -> Bool {
        guard let channelManager = channelManager else {
            throw NodeError.Channels.channelManagerNotFound
        }
        
        // Create the funding transaction and do the `funding_created/funding_signed` dance with our counterparty.
        // After that, LDK will automatically broadcast it via the `BroadcasterInterface` we gave `ChannelManager`.
        var fundingResult: LightningDevKit.Result_NoneAPIErrorZ
        
        fundingResult = channelManager.fundingTransactionGenerated(
            temporaryChannelId: channelOpenInfo.temporaryChannelId,
            counterpartyNodeId: channelOpenInfo.counterpartyNodeId,
            fundingTransaction: fundingTransaction
        )
        
        if fundingResult.isOk() {
            return true
        } else if let error = fundingResult.getError()?.getLDKError() {
            throw error
        }
        
        throw NodeError.Channels.fundingFailure
    }
    //MARK: - Create invoice
    public func createInvoice(satAmount: UInt64?, description: String) async -> String? {
        guard let channelManager = channelManager, let keyInterface = keysManager else {
            return nil
        }
        
        var mSatAmount: UInt64?
        if let satAmount = satAmount {
            mSatAmount = satAmount * 1000
        }

        let result = Bindings.createInvoiceFromChannelmanager(
            channelmanager: channelManager,
            nodeSigner: keyInterface.asNodeSigner(),
            logger: logger,
            network: .Regtest,
            amtMsat: mSatAmount,
            description: description,
            invoiceExpiryDeltaSecs: 86400,
            minFinalCltvExpiryDelta: nil
        )
        
        if result.isOk(), let invoice = result.getValue() {
            let invoiceString = invoice.toStr()
            print("================================")
            print("INVOICE: \(invoiceString)")
            print("================================")
            
            return invoiceString
        } else if let error = result.getError() {
            print(error.toStr())
            return nil
        }
        
        return nil
    }
    
    //MARK: - Create invoice
    public func createInvoice(paymentHash: String, satAmount: UInt64) async -> Invoice? {
        guard let channelManager = channelManager, let keyInterface = keysManager else {
            return nil
        }
        
        let mSatAmount: UInt64 = satAmount * 1000
                
        let result = Bindings.createInvoiceFromChannelmanagerAndDurationSinceEpochWithPaymentHash(
            channelmanager: channelManager,
            nodeSigner: keyInterface.asNodeSigner(),
            logger: logger,
            network: .Regtest,
            amtMsat: mSatAmount,
            description: String(),
            durationSinceEpoch: UInt64(Date().timeIntervalSince1970),
            invoiceExpiryDeltaSecs: 86400,
            paymentHash: paymentHash.toByteArray(),
            minFinalCltvExpiryDelta: nil
        )
        
        if result.isOk(), let invoice = result.getValue() {
            return invoice
        } else if let error = result.getError() {
            print(error.toStr())
            return nil
        }
        
        return nil
    }
    
    //MARK: - Pay invoice
    public func pay(invoice: Invoice) async throws -> LightningPayment {
        guard let manager = channelManager else {
            throw NodeError.noPayer
        }
        
        let result = Bindings.payInvoice(invoice: invoice, retryStrategy: .initWithAttempts(a: 3), channelmanager: manager)
        
        if result.isOk() {
            guard let event = await pendingEventTracker.await(events: [.paymentFailed, .paymentSent], timeout: 5) else {
                throw NodeError.error("Not received paymentFailed or paymentSent event. Timeout error")
            }
            
            print("Pay invoice expected event: \(event.getValueType())")
            
            switch event.getValueType() {
            case .PaymentSent:
                guard let paymentSent = event.getValueAsPaymentSent() else {
                    throw NodeError.error("getValueAsPaymentSent is nil")
                }
                
                let paymentID = paymentSent.getPaymentId().toHexString()
                let preimage = paymentSent.getPaymentPreimage().toHexString()
                let fee = (paymentSent.getFeePaidMsat() ?? 0)/1000
                let timestamp = Int(Date().timeIntervalSince1970)
                
                let payment = LightningPayment(
                    nodeId: channelManager?.getOurNodeId().toHexString() ?? "-",
                    paymentId: paymentID,
                    amount: (invoice.amountMilliSatoshis() ?? 0)/1000,
                    preimage: preimage,
                    type: .sent,
                    timestamp: timestamp,
                    fee: fee
                )
                                
                switch fileManager.persist(payment: payment) {
                case .success:
                    print("payment \(paymentID) persisted")
                case .failure(let error):
                    print("Unable to persist payment \(paymentID): \(error.localizedDescription)")
                }
                
                return payment
            case .PaymentFailed:
                guard let paymentFailed = event.getValueAsPaymentFailed() else {
                    throw NodeError.error("getValueAsPaymentFailed is nil")
                }
                
                let errorMessage = "Payment failed:\nid: \(paymentFailed.getPaymentId().toHexString())\nhash: \(paymentFailed.getPaymentHash().toHexString())"
                print(errorMessage)
                
                throw NodeError.error(errorMessage)
            default:
                print(event.getValueType())
                throw NodeError.Channels.wrongLDKEvent
            }
        } else if let invoicePayError = result.getError() {
            if let error = invoicePayError.getValueAsInvoice() {
                print("Invoice error: \(error)")
                throw NodeError.error("Invoice error: \(error)")
            } else if let error = invoicePayError.getValueAsSending() {
                print("Sending error")
                switch error {
                case .RouteNotFound:
                    print("RouteNotFound")
                    throw NodeError.error("RouteNotFound")
                case .DuplicatePayment:
                    print("DuplicatePayment")
                    throw NodeError.error("DuplicatePayment")
                case .PaymentExpired:
                    print("PaymentExpired")
                    throw NodeError.error("PaymentExpired")
                @unknown default:
                    print("Unknown invoice paer error")
                    throw NodeError.error("Unknown invoice paer error")
                }
            } else {
                print("Unknown error")
                throw NodeError.error("unknown error")
            }
        } else {
            print("Unknown error")
            throw NodeError.error("Unknow error")
        }
    }
    
    public func broacastTransaction(tx: [UInt8]) {
        broadcaster?.broadcastTransaction(tx: tx)
    }
    
    public func getFundingTransactionScriptPubKey(outputScript: [UInt8]) async -> String? {
        guard let rpcInterface = rpcInterface,
              let decodedScript = try? await rpcInterface.decodeScript(script: outputScript),
              let address = decodedScript["address"] as? String else {
            return nil
        }

        return address
    }
    
    public func decodeAddress(outputScript: [UInt8]) async -> String? {
        guard let rpcInterface = rpcInterface,
              let decodedScript = try? await rpcInterface.decodeScript(script: outputScript),
              let segwitData = decodedScript["segwit"] as? [String: Any] else {
            return nil
        }

        return segwitData["address"] as? String
    }
    
    public func getDescriptorInfo(descriptor: String) async throws -> String? {
        guard let rpcInterface = rpcInterface else { return nil }
        return try await rpcInterface.getDescriptorInfo(descriptor: descriptor)
    }
    
    public func scanTxOutSet(descriptor: String) async throws -> [String: Any] {
        guard let rpcInterface = rpcInterface else { return [:] }
        return try await rpcInterface.scanTxOutSet(descriptor: descriptor)
    }
    
    public func generate(blocks: Int, toAddress: String) async throws -> [String] {
        guard let rpcInterface = rpcInterface else { return [] }
        return try await rpcInterface.mineBlocks(number: blocks, coinbaseDestinationAddress: toAddress)
    }
    
    //MARK: - Sends funding transaction generated message
    public func fundingTransactionGenerated(temporaryChannelId: [UInt8], fundingTransaction: [UInt8]) -> Result_NoneAPIErrorZ {
        guard let channelManager = channelManager else {
            return .initWithErr(e: .initWithApimisuseError(err: "Channel Manager is nil"))
        }
        return channelManager.fundingTransactionGenerated(
            temporaryChannelId: temporaryChannelId,
            counterpartyNodeId: [],
            fundingTransaction: fundingTransaction
        )
    }
    //MARK: - Close channel
    public func close(channel: ChannelDetails) async {
        guard let channelId = channel.getChannelId() else { return }
        let counterpartyNodeId = channel.getCounterparty().getNodeId()
        let result = channelManager!.closeChannel(channelId: channelId, counterpartyNodeId: counterpartyNodeId)
        
        if result.isOk() {
            print("closed")
        } else if let channelCloseError = result.getError() {
            print("error type: \(String(describing: channelCloseError.getValueType()))")
            if let error = channelCloseError.getValueAsApiMisuseError() {
                print("API misuse error: \(error.getErr())")
            } else if let error = channelCloseError.getValueAsChannelUnavailable() {
                print("channel unavailable error: \(error.getErr())")
            } else if let error = channelCloseError.getValueAsFeeRateTooHigh() {
                print("excessive fee rate error: \(error.getErr())")
            } else if let error = channelCloseError.getValueAsIncompatibleShutdownScript() {
                print("incompatible shutdown script: \(error.getScript())")
            } else if let error = channelCloseError.getValueAsInvalidRoute() {
                print("route error: \(error.getErr())")
            }
        }
    }
    //MARK: - Decode invoice
    public func decode(invoice: String) throws -> Invoice {
        let decodedInvoice = Invoice.fromStr(s: invoice)
        guard decodedInvoice.isOk() else {
            throw NodeError.Invoice.decodingError
        }
        if let invoice = decodedInvoice.getValue() {
            return invoice
        } else {
            throw NodeError.Invoice.decodingError
        }
    }
    
    public func claimFunds(preimage: [UInt8]) {
        channelManager?.claimFunds(paymentPreimage: preimage)
    }
    
    public func handleSpendableOutputs(descriptors: [SpendableOutputDescriptor], changeDestinationScript: [UInt8]) {
        guard let km = keysManager else { return }
        
        for descriptor in descriptors {
            let valueType = descriptor.getValueType()
            
            print("Spendable output Descriptor with type: \(valueType)")
            
            switch valueType {
            case .StaticOutput:
                
                let staticOutput = descriptor.getValueAsStaticOutput()!
                
                let output = staticOutput.getOutput()
                let outpoint = staticOutput.getOutput()
                
                print("Output script pub key: \(output.getScriptPubkey().toHexString())")
                print("Output value: \(output.getValue())")

                print("Outpoint script pub key: \(outpoint.getScriptPubkey().toHexString())")
                print("Outpoint value: \(outpoint.getValue())")
            case .DelayedPaymentOutput:
                let delayedPaymentOutput = descriptor.getValueAsDelayedPaymentOutput()!.getOutput()
                                
                print("Output script pub key: \(delayedPaymentOutput.getScriptPubkey().toHexString())")
                print("Output value: \(delayedPaymentOutput.getValue())")
            case .StaticPaymentOutput:
                let staticPaymentOutput = descriptor.getValueAsStaticPaymentOutput()
                
                if let output = staticPaymentOutput?.getOutput() {
                    print("Output script pub key: \(output.getScriptPubkey().toHexString())")
                    print("Output value: \(output.getValue())")
                }
                if let outpoint = staticPaymentOutput?.getOutput() {
                    print("Outpoint script pub key: \(outpoint.getScriptPubkey().toHexString())")
                    print("Outpoint value: \(outpoint.getValue())")
                }
            @unknown default:
                break
            }
        }
                
        let rawSpendableTx = km.spendSpendableOutputs(
            descriptors: descriptors,
            outputs: [],
            changeDestinationScript: changeDestinationScript,
            feerateSatPer1000Weight: 7500
        )
        
        guard rawSpendableTx.isOk(), let value = rawSpendableTx.getValue() else  {
            print("Failed to spend output")
            return
        }
        
        print("Transaction to spend: ")
        print(value.toHexString())
        
        broadcaster?.broadcastTransaction(tx: value)
    }
    
    public func processPendingHTLCForwards() {
        channelManager?.processPendingHtlcForwards()
    }
    
    public func subscribeForNodeEvents() async -> AsyncStream<Event> {
        await pendingEventTracker.subscribe()
    }
    
    public func cooperativeCloseChannel(id: [UInt8], counterPartyId: [UInt8]) {
        guard let cm = channelManager else { return }
        
        let result = cm.closeChannelWithTargetFeerate(channelId: id, counterpartyNodeId: counterPartyId, targetFeerateSatsPer1000Weight: 8500)
        
        if result.isOk() {
            print("Channel with id: \(id.toHexString()) is closed")
        } else if let error = result.getError() {
            print("Channel with id: \(id.toHexString()) close error: \(error)")
        }
    }
    
    public func forceCloseChannel(id: [UInt8], counterPartyId: [UInt8]) {
        guard let cm = channelManager else { return }
        let result = cm.forceCloseBroadcastingLatestTxn(channelId: id, counterpartyNodeId: counterPartyId)
        
        if result.isOk() {
            print("Channel with id: \(id.toHexString()) is closed")
        } else if let error = result.getError() {
            print("Channel with id: \(id.toHexString()) close error: \(error)")
        }
    }
}

extension Node {
    public struct ChannelOpenInfo {
        private let fundingEvent: Event.FundingGenerationReady
        public var fundingOutputScript: [UInt8] {
            fundingEvent.getOutputScript()
        }
        public var temporaryChannelId: [UInt8] {
            fundingEvent.getTemporaryChannelId()
        }
        public let counterpartyNodeId: [UInt8]
        
        init(fundingEvent: Event.FundingGenerationReady, counterpartyNodeId: [UInt8]) {
            self.fundingEvent = fundingEvent
            self.counterpartyNodeId = counterpartyNodeId
        }
    }
}

// MARK: Publishers
extension Node {
    public var connectedPeers: AnyPublisher<[String], Never> {
        Timer.publish(every: 1, on: .main, in: .default)
            .autoconnect()
            .prepend(Date())
            .filter { [weak self] _ in self?.peerManager != nil }
            .flatMap { [weak self] _ -> AnyPublisher<[String], Never> in
                let peers = self?.peerManager!.getPeerNodeIds().compactMap { $0.0.toHexString() }
                return Just(peers ?? []).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}


// MARK: Helpers
extension Node {
    /// Receives downstream events from an upstream `Publisher` of `RpcChainManager`. Primarily used for reconciling chain tip.
    private func subscribeToChainPublisher() throws {
        guard let rpcInterface = rpcInterface else {
            throw NodeError.noChainManager
        }
        
        rpcInterface.blockchainMonitorPublisher
            .sink(receiveCompletion: { error in
                print("Error subscribing to blockchain monitor")
            }, receiveValue: { [unowned self] _ in
                if let channelManagerConstructor = channelManagerConstructor, let persister = persister {
                    channelManagerConstructor.chainSyncCompleted(persister: persister)
                    let bestBLockHeight = channelManagerConstructor.channelManager.currentBestBlock().height()
                    print("LDK CHANNEL MANAGER BEST BLOCK: \(bestBLockHeight)\n")
                } else {
                    print("Chain Tip Reconcilation Failed.")
                }
            })
            .store(in: &cancellables)
    }
    
    private func initNetworkGraph() -> NetworkGraph {
        guard let serializedGraph = fileManager.getSerializedNetworkGraph() else {
            return NetworkGraph(network: .Regtest, logger: logger)
        }
        
        let read = NetworkGraph.read(ser: serializedGraph, arg: logger)
        
        guard read.isOk() else {
            return NetworkGraph(network: .Regtest, logger: logger)
        }
        
        guard let networkGraph = read.getValue() else {
            return NetworkGraph(network: .Regtest, logger: logger)
        }
        
        return networkGraph
    }
    
    private func initProbabilisticScorer(networkGraph: NetworkGraph, logger: Logger) -> ProbabilisticScorer {
        let scoringParams = ProbabilisticScoringParameters.initWithDefault()
        
        // commented out unil https://github.com/lightningdevkit/ldk-swift/pull/103 merged to fix the crash of the scorer
        
//        guard let serializedScorer = fileManager.getSerializedScorer() else {
//            return ProbabilisticScorer(params: scoringParams, networkGraph: networkGraph, logger: logger)
//        }
//
//        let read = ProbabilisticScorer.read(ser: serializedScorer, argA: scoringParams, argB: networkGraph, argC: logger)
//
//        guard read.isOk() else {
//            return ProbabilisticScorer(params: scoringParams, networkGraph: networkGraph, logger: logger)
//        }
//
//        guard let scorer = read.getValue() else {
            return ProbabilisticScorer(params: scoringParams, networkGraph: networkGraph, logger: logger)
//        }
//
//        return scorer
    }
    
    /// Used for loading a channel manager from the Documents directory.
    private func loadChannelManagerConstructor(params: ChannelManagerConstructionParameters) async throws -> ChannelManagerConstructor {
        if let channelManager = fileManager.getSerializedChannelManager(),
           let networkGraph = fileManager.getSerializedNetworkGraph() {
            let channelMonitors = fileManager.getSerializedChannelMonitors()
            do {
                return try ChannelManagerConstructor(
                    channelManagerSerialized: channelManager,
                    channelMonitorsSerialized: channelMonitors,
                    netGraphSerialized: networkGraph,
                    filter: filter,
                    params: params
                )
            } catch {
                throw NodeError.noChannelManager
            }
        } else {
            throw NodeError.channelMaterialNotFound
        }
    }
    
    private func initializeChannelMaterialAndNetworkGraph(currentTipHash: [UInt8], currentTipHeight: UInt32, networkGraph: NetworkGraph, params: ChannelManagerConstructionParameters) async throws -> ChannelManagerConstructor {
        let network: Bindings.Network
        
        switch connectionType {
        case .testnet:
            network = .Testnet
        default:
            network = .Regtest
        }
                        
        return ChannelManagerConstructor(
            network: network,
            currentBlockchainTipHash: currentTipHash,
            currentBlockchainTipHeight: currentTipHeight,
            netGraph: networkGraph,
            params: params
        )
    }
}
