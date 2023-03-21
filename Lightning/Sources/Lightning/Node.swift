//
//  Node.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation
import Combine
import LightningDevKit

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
    
    var blockchainListener: ChainListener?
    
    var cancellables = Set<AnyCancellable>()
    
    // We declare this here because `ChannelManagerConstructor` and `ChainMonitor` will share a reference to them
    let logger = Logger()
    let feeEstimator = FeeEstimator()
    let filter = Filter()
    
    // all user channels
    public var allChannels: [ChannelDetails] {
        channelManager?.list_channels() ?? []
    }
    // usable user channels
    public var usableChannels: [ChannelDetails] {
        channelManager?.list_usable_channels() ?? []
    }

    public var totalBalance: UInt64 {
        usableChannels.map{ $0.get_balance_msat() }.reduce(0){ $0 + $1 }
    }
    
    public init(type: ConnectionType) {
        self.connectionType = type
    }
    
    /// Start the Lightning node
    public func start() async throws {
        // (1) Retrieve our key's 32-byte seed
        guard let keySeed = fileManager.getKeysSeed() else { throw NodeError.keySeedNotFound }
        
        let timestampInSeconds = UInt64(Date().timeIntervalSince1970)
        let timestampInNanoseconds = UInt32(truncating: NSNumber(value: timestampInSeconds * 1000 * 1000))
        
        // (2) Setup KeysManager with `keySeed`. With add entropy using the current time. See this comment for more information: https://docs.rs/lightning/0.0.112/lightning/chain/keysinterface/struct.KeysManager.html#method.new
        keysManager = KeysManager(seed: keySeed, starting_time_secs: timestampInSeconds, starting_time_nanos: timestampInNanoseconds)
        
        // (3) Grabs an instance of KeysInterface, we will need it later to construct a ChannelManager
        guard let keysInterface = keysManager?.as_KeysInterface() else {
            throw NodeError.keyInterfaceFailure
        }
        
        // (4) Initialize rpcInterface, which represents a series of chain methods that are necessary for chain sync.
        // interact with different types of block sources with just a different choice of a `RpcChainManager` instance.
        switch connectionType {
        case .regtest:
            fatalError("Not yet implemented")
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
            chain_source: Option_FilterZ(value: filter),
            broadcaster: broadcaster!, // Force unwrap since we definitely set it in L61
            logger: logger,
            feeest: feeEstimator,
            persister: ChannelPersister()
        )
        
        // (7) Do requisite chain sync to start.
        if case .regtest = connectionType, let rpcInterface = rpcInterface as? BitcoinCoreChainManager {
            // If we're using Bitcoin Core
            try await rpcInterface.preloadMonitor(anchorHeight: .chaintip)
        }
        
        if case .testnet = connectionType, let rpcInterface = rpcInterface as? BlockStreamChainManager {
            // If we're using BlockStream
            try await rpcInterface.preloadMonitor(anchorHeight: .chaintip)
        }
        // we will tell the ChainMonitor to connect blocks up to the latest chain tip.
        
        // (8) Construct ChannelManager. The ChannelManager, as mentioned earlier, is like the brain of the node. It is responsible for
        // sending messages to appropriate channels, track HTLCs, forward onion packets, and also track a user's channels. It can also be
        // persisted on disk, which is what you generally want to do as often as possible -- this is equivalent to a "node backup".
        // The general advice here is to make sure that your `ChannelManager` *is encrypted*, because you can certainly glean information
        // about a user's payment history if they get leaked out in the clear.
        if fileManager.hasChannelMaterialAndNetworkGraph {
            // Load our channel manager from disk
            channelManagerConstructor = try await loadChannelManagerConstructor(keysInterface: keysInterface, chainMonitor: chainMonitor)
        } else {
            // An existing ChannelManager does not exist on disk, create new channel material and network graph
            let chaintipHeight = try await rpcInterface.getChaintipHeight()
            let chaintipHash = try await rpcInterface.getChaintipHash()
            let reversedChaintipHash = [UInt8](chaintipHash.reversed())
            
            channelManagerConstructor = try await initializeChannelMaterialAndNetworkGraph(
                currentTipHash: reversedChaintipHash,
                currentTipHeight: chaintipHeight,
                keysInterface: keysInterface,
                chainMonitor: chainMonitor,
                broadcaster: broadcaster! // Force unwrap since we definitely set it in L78
            )
        }
        
        guard let channelManagerConstructor = channelManagerConstructor else {
            throw NodeError.noChannelManager
        }
        
        // Create shared instance reference to these objects, so we can use them for opening and managing channels and connecting to peers,
        // respectively.
        channelManager = channelManagerConstructor.channelManager
        peerManager = channelManagerConstructor.peerManager
        tcpPeerHandler = channelManagerConstructor.getTCPPeerHandler()
        
        // (9) Initialize Persister, which is primarily responsible for persisting `ChannelManager`, `Scorer`, and `NetworkGraph` to disk.
        persister = Persister(eventTracker: pendingEventTracker)
        guard let channelManager = channelManager else {
            throw NodeError.noChannelManager
        }
        
        blockchainListener = ChainListener(channelManager: channelManager, chainMonitor: chainMonitor)
        
        let isMonitoring = await rpcInterface.isMonitoring()

        if !isMonitoring {
            try subscribeToChainPublisher()
        } else {
            print("Monitor already running")
        }
     
        print("LDK is Running with key: \(channelManager.get_our_node_id().toHexString())")
    }
    
    //MARK: - Connect to peer
    public func connectPeer(pubKey: String, hostname: String, port: UInt16) async throws {
        print("Connecting to peer \(pubKey)")
        
        guard let _ = peerManager, let tcpPeerHandler = tcpPeerHandler else {
            throw NodeError.connectPeer
        }
        
        let connected = tcpPeerHandler.connect(address: hostname, port: port, theirNodeId: pubKey.toByteArray())
        
        print("peer \(pubKey) is connected: \(connected)")
    }
    //MARK: - Open channel request
    public func requestChannelOpen(_ pubKeyHex: String, channelValue: UInt64, reserveAmount: UInt64) async throws -> ChannelOpenInfo {
        guard let channelManager = channelManager else {
            throw NodeError.Channels.channelManagerNotFound
        }
        
        // open_channel
        let theirNodeId = pubKeyHex.toByteArray()
        let config = UserConfig()
        let userChannelId = UInt64.random(in: 1...9999)
        print("user channel id \(userChannelId)")

        let channelOpenResult = channelManager.create_channel(
            their_network_key: theirNodeId,
            channel_value_satoshis: channelValue,
            push_msat: reserveAmount,
            user_channel_id: 42,
            override_config: config
        )
        
        // See if peer has returned `accept_channel`
        if channelOpenResult.isOk() {
            let managerEvents = await getManagerEvents(expectedCount: 1)
            let managerEvent = managerEvents[0]
            let eventValueType = managerEvent.getValueType()
                        
            switch eventValueType {
            case .some(let wrapped):
                switch wrapped {
                case .FundingGenerationReady:
                    let fundingReadyEvent = managerEvent.getValueAsFundingGenerationReady()!
                    
                    return ChannelOpenInfo(
                        fundingEvent: fundingReadyEvent,
                        counterpartyNodeId: pubKeyHex.toByteArray()
                    )
                default: throw NodeError.Channels.unknown
                }
            default: throw NodeError.Channels.unknown
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
        fundingResult = channelManager.funding_transaction_generated(
            temporary_channel_id: channelOpenInfo.temporaryChannelId,
            counterparty_node_id: channelOpenInfo.counterpartyNodeId,
            funding_transaction: fundingTransaction
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
        guard let channelManager = channelManager, let keyInterface = keysManager?.as_KeysInterface() else {
            return nil
        }
        
        var mSatAmount: UInt64?
        if let satAmount = satAmount {
            mSatAmount = satAmount * 1000
        }
        
        let result = Bindings.swift_create_invoice_from_channelmanager(
            channelmanager: channelManager,
            keys_manager: keyInterface,
            network: LDKCurrency_BitcoinTestnet,
            amt_msat: Option_u64Z(value: mSatAmount),
            description: description,
            invoice_expiry_delta_secs: 86400 //24 hours
        )
        
        if result.isOk(), let invoice = result.getValue() {
            let invoiceString = invoice.to_str()
            print("================================")
            print("INVOICE: \(invoiceString)")
            print("================================")
            
            return invoiceString
        } else if let error = result.getError() {
            print(error.to_str())
            return nil
        }
        
        return nil
    }
    //MARK: - Sends funding transaction generated message
    public func fundingTransactionGenerated(temporaryChannelId: [UInt8], fundingTransaction: [UInt8]) -> Result_NoneAPIErrorZ {
        guard let channelManager = channelManager else {
            return Result_NoneAPIErrorZ.err(e: .apimisuse_error(err: "Channel Manager is nil"))
        }
        return channelManager.funding_transaction_generated(
            temporary_channel_id: temporaryChannelId,
            counterparty_node_id: [],
            funding_transaction: fundingTransaction
        )
    }
    //MARK: - Close channel
    public func close(channel: ChannelDetails) async {
        let channelId = channel.get_channel_id()
        let counterpartyNodeId = channel.get_counterparty().get_node_id()
        let result = channelManager!.close_channel(channel_id: channelId, counterparty_node_id: counterpartyNodeId)
        
        if result.isOk() {
            print("closed")
        } else if let channelCloseError = result.getError() {
            print("error type: \(String(describing: channelCloseError.getValueType()))")
            if let error = channelCloseError.getValueAsAPIMisuseError() {
                print("API misuse error: \(error.getErr())")
            } else if let error = channelCloseError.getValueAsChannelUnavailable() {
                print("channel unavailable error: \(error.getErr())")
            } else if let error = channelCloseError.getValueAsFeeRateTooHigh() {
                print("excessive fee rate error: \(error.getErr())")
            } else if let error = channelCloseError.getValueAsIncompatibleShutdownScript() {
                print("incompatible shutdown script: \(error.getScript())")
            } else if let error = channelCloseError.getValueAsRouteError() {
                print("route error: \(error.getErr())")
            }
        }
    }
    //MARK: - Decode invoice
    public func decode(invoice: String) throws -> Invoice? {
        let decodedInvoice = Invoice.from_str(s: invoice)
        guard decodedInvoice.isOk() else {
            throw NodeError.Invoice.decodingError
        }
        return decodedInvoice.getValue()
    }
}

extension Node {
    public struct ChannelOpenInfo {
        private let fundingEvent: Event.FundingGenerationReady
        public var fundingOutputScript: [UInt8] {
            fundingEvent.getOutput_script()
        }
        public var temporaryChannelId: [UInt8] {
            fundingEvent.getTemporary_channel_id()
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
        Timer.publish(every: 5, on: .main, in: .default)
            .autoconnect()
            .filter { [weak self] _ in self?.peerManager != nil }
            .flatMap { [weak self] _ -> AnyPublisher<[String], Never> in
                let peers = self?.peerManager!.get_peer_node_ids().compactMap { $0.toHexString() }
                return Just(peers ?? [])
                    .eraseToAnyPublisher()
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
                print("CasaLDK: Error subscribing to blockchain monitor")
            }, receiveValue: { [unowned self] _ in
                if let channelManagerConstructor = channelManagerConstructor,
                    let networkGraph = channelManagerConstructor.net_graph,
                    let persister = persister {
                    let scoringParams = ProbabilisticScoringParameters()
                    let probabalisticScorer = ProbabilisticScorer(params: scoringParams, network_graph: networkGraph, logger: logger)
                    let score = probabalisticScorer.as_Score()
                    
                    channelManagerConstructor.chain_sync_completed(persister: persister, scorer: MultiThreadedLockableScore(score: score))
                    
                    print("Reconciled Chain Tip")
                } else {
                    print("CasaLDK: Chain Tip Reconcilation Failed. ChannelManagerConstructor does not have a network graph!")
                }
            })
            .store(in: &cancellables)
    }
    
    /// Used for loading a channel manager from the Documents directory.
    private func loadChannelManagerConstructor(keysInterface: KeysInterface, chainMonitor: ChainMonitor) async throws -> ChannelManagerConstructor {
        if let channelManager = fileManager.getSerializedChannelManager(),
           let networkGraph = fileManager.getSerializedNetworkGraph() {
            let channelMonitors = fileManager.getSerializedChannelMonitors()
            do {
                return try ChannelManagerConstructor(
                    channel_manager_serialized: channelManager,
                    channel_monitors_serialized: channelMonitors,
                    keys_interface: keysInterface,
                    fee_estimator: feeEstimator,
                    chain_monitor: chainMonitor,
                    filter: filter,
                    net_graph_serialized: networkGraph,
                    tx_broadcaster: broadcaster!, // Force unwrap since we definitely set it in L72
                    logger: logger,
                    enableP2PGossip: true
                )
            } catch {
                throw NodeError.noChannelManager
            }
        } else {
            throw NodeError.channelMaterialNotFound
        }
    }
    
    private func initializeChannelMaterialAndNetworkGraph(currentTipHash: [UInt8], currentTipHeight: UInt32, keysInterface: KeysInterface, chainMonitor: ChainMonitor, broadcaster: BroadcasterInterface) async throws -> ChannelManagerConstructor {
        var network = LDKNetwork_Regtest
        switch connectionType {
        case .testnet:
            network = LDKNetwork_Testnet
        default:
            network = LDKNetwork_Regtest
        }
        
        let genesisHash = [UInt8](repeating: 0, count: 32)
        
        let graph = NetworkGraph(genesis_hash: genesisHash, logger: logger)
        return ChannelManagerConstructor(
            network: network,
            config: UserConfig(),
            current_blockchain_tip_hash: currentTipHash,
            current_blockchain_tip_height: currentTipHeight,
            keys_interface: keysInterface,
            fee_estimator: feeEstimator,
            chain_monitor: chainMonitor,
            net_graph: graph,
            tx_broadcaster: broadcaster,
            logger: logger,
            enableP2PGossip: true
        )
    }
    
    private func getManagerEvents(expectedCount: UInt) async -> [Event] {
       if let _ = channelManagerConstructor {
           while true {
               if await self.pendingEventTracker.getCount() >= expectedCount {
                   return await self.pendingEventTracker.getAndClearEvents()
               }
               await self.pendingEventTracker.awaitAddition()
           }
       }
       return []
   }
}
