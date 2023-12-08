//
//  LdkNode.swift
//  PortalTests
//
//  Created by farid on 22.11.2023.
//

import Foundation
import LightningDevKit
import Combine
import PortalSwapSDK
import Promises

class LdkNode {
    enum NodeError: Error {
        case failedObtainSelf, failedObtainChannelManager, failedObtainKeyManager, msg(String)
    }
    
    private let rpcInterface: RegtestBlockchainManager!
    private let keysManager: KeysManager!
    private let broadcaster: BroadcasterInterface!
    private let channelManagerConstructor: ChannelManagerConstructor!
    let channelManager: ChannelManager!
    private let channelMonitorPersister: Persist!
    private let channelManagerAndNetworkGraphPersisterAndEventHandler: LDKTraitImplementations.PlaynetChannelManagerAndNetworkGraphPersisterAndEventHandler!
    private let peerManager: PeerManager!
    private let tcpPeerHandler: TCPPeerHandler!
    private let config: UserConfig!
    private let logger: Logger!
    private var hodlInvoices = [HodlInvoice]()
    private let instanceId: String
    
    struct LDKNodeConfig {
        let btcRpcConfig: BitcoinRpcConfig
        let ldnPeerProps: LNDProps
    }
    
    struct LNDProps {
        let pubKey: String
        let address: String
        let port: UInt16
    }
    
    struct BitcoinRpcConfig {
        let rpcProtocol: BlockchainObserver.RpcProtocol
        let rpcDomain: String
        let rpcPort: UInt
        let rpcUsername: String
        let rpcPassword: String
    }
    
    private let ldnPeerProps: LNDProps
    private var cancellables = Set<AnyCancellable>()
        
    init(instanceId: String, ldnPeerProps: LNDProps, rpcInterface: RegtestBlockchainManager) async throws {
        self.instanceId = instanceId
        self.ldnPeerProps = ldnPeerProps
        self.rpcInterface = rpcInterface
        
        try await rpcInterface.preloadMonitor(anchorHeight: .chaintip)
        
        var seed = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, seed.count, &seed)

        let timestamp_seconds = UInt64(NSDate().timeIntervalSince1970)
        let timestamp_nanos = UInt32(truncating: NSNumber(value: timestamp_seconds * 1000 * 1000))
        
        keysManager = KeysManager(seed: seed, startingTimeSecs: timestamp_seconds, startingTimeNanos: timestamp_nanos)
        
        logger = LDKTraitImplementations.PlaynetLogger(id: instanceId, logLevels: [.Warn, .Error])

        config = UserConfig.initWithDefault()
        
        let lightningNetwork: LightningDevKit.Network = .Regtest
        let chaintipHash = try await rpcInterface.getChaintipHash()
        let reversedChaintipHash = [UInt8](chaintipHash.reversed())
        let chaintipHeight = try await rpcInterface.getChaintipHeight()
        let networkGraph = NetworkGraph(network: .Regtest, logger: logger)

        let probabalisticScorer = ProbabilisticScorer(decayParams: .initWithDefault(), networkGraph: networkGraph, logger: logger)
        let score = probabalisticScorer.asScore()
        let multiThreadedScorer = MultiThreadedLockableScore(score: score)

        let feeEstimator = LDKTraitImplementations.PlaynetFeeEstimator()
        
        broadcaster = LDKTraitImplementations.PlaynetBroadcaster(rpcInterface: rpcInterface)
        
        channelMonitorPersister = LDKTraitImplementations.PlaynetChannelMonitorPersister()
        
        channelManagerAndNetworkGraphPersisterAndEventHandler = LDKTraitImplementations.PlaynetChannelManagerAndNetworkGraphPersisterAndEventHandler(id: instanceId)
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
        
        channelManagerConstructor = ChannelManagerConstructor(
            network: lightningNetwork,
            currentBlockchainTipHash: reversedChaintipHash,
            currentBlockchainTipHeight: UInt32(chaintipHeight),
            netGraph: networkGraph,
            params: channelManagerConstructorParameters
        )
        
        channelManager = channelManagerConstructor.channelManager
        
        peerManager = channelManagerConstructor.peerManager
        tcpPeerHandler = channelManagerConstructor.getTCPPeerHandler()

        let listener = LDKTraitImplementations.Listener(channelManager: channelManager, chainMonitor: chainMonitor)
        rpcInterface.registerListener(listener)
        
        channelManagerConstructor.chainSyncCompleted(persister: channelManagerAndNetworkGraphPersisterAndEventHandler)
        
        try subscribeToChainPublisher()
        try subscribeToNodeEvents()
    }
        
    public func handleNodeEvent(_ event: Event) {
        switch event.getValueType() {
        case .PaymentPathSuccessful:
            print("\(instanceId) received LDK event: PaymentPathSuccessful")
        case .FundingGenerationReady:
            print("\(instanceId) received LDK event: FundingGenerationReady")
        case .PaymentClaimable:
            print("\(instanceId) received LDK event: PaymentClaimable")
                        
            let paymentClaimableEvent = event.getValueAsPaymentClaimable()!
            let paymentHashData = paymentClaimableEvent.getPaymentHash()
            let paymentHashString = paymentHashData.toHexString()
            
            let paymentPurpose = paymentClaimableEvent.getPurpose()
            
            switch paymentPurpose.getValueType() {
            case .InvoicePayment:
                let invoicePayment = paymentPurpose.getValueAsInvoicePayment()!
                let paymentSecret = invoicePayment.getPaymentSecret()
                
                if let paymentPreimage = invoicePayment.getPaymentPreimage() {
                    claimFunds(preimage: paymentPreimage)
                } else {
                    let getPaymentPreimageResult = channelManager.getPaymentPreimage(paymentHash: paymentHashData, paymentSecret: paymentSecret)
                    if getPaymentPreimageResult.isOk(), let paymentPreimage = getPaymentPreimageResult.getValue() {
                        claimFunds(preimage: paymentPreimage)
                    } else {
                        if let hodlInvoice = hodlInvoices.first(where: { $0.id == paymentHashString}) {
                            print("\(instanceId) Received Payment Claimable for Hodl invoice with id: \(hodlInvoice.id)")
                            hodlInvoice.update(status: .paymentHeld)
                        } else {
                            print("\(instanceId) Received claimable event with unknown preimage, cannot claim")
                        }
                    }
                }
            case .SpontaneousPayment:
                print("\(instanceId) SpontaneousPayments not handled yet")
            @unknown default:
                print("\(instanceId) Unknown payment purpose")
                break
            }
        case .PaymentClaimed:
            print("\(instanceId) received PaymentClaimed")
            
            let value = event.getValueAsPaymentClaimed()!
            let amount = value.getAmountMsat()/1000
            print("Amount: \(amount)")
            let paymentId = value.getPaymentHash().toHexString()
            print("Payment \(paymentId) claimed")
                
            let paymentPurpose = value.getPurpose()
            let invoicePayment = paymentPurpose.getValueAsInvoicePayment()!
            let preimage = invoicePayment.getPaymentPreimage()
            let timestamp = Int(Date().timeIntervalSince1970)

            if let hodlInvoice = hodlInvoices.first(where: { $0.id == paymentId}) {
                hodlInvoice.update(status: .paymentConfirmed)
            } else {
                print("cannot find hodlInvoice")
            }
        case .PaymentSent:
            print("\(instanceId) received LDK event: PaymentSent")
        case .PaymentFailed:
            print("\(instanceId) received LDK event: PaymentFailed")
            
            let value = event.getValueAsPaymentFailed()!
            
            print("payment ID: \(value.getPaymentId().toHexString())")
            print("payment hash: \(value.getPaymentHash().toHexString())")
        case .PaymentPathFailed:
            print("\(instanceId) received LDK event: PaymentPathFailed")
            
            let value = event.getValueAsPaymentPathFailed()!
            print("all paths failed - \(value.getPaymentFailedPermanently() ? "yes" : "no")")
        case .ProbeSuccessful:
            print("\(instanceId) received LDK event: ProbeSuccessful")

        case .ProbeFailed:
            print("\(instanceId) received LDK event: ProbeFailed")

        case .PendingHTLCsForwardable:
            print("\(instanceId) received LDK event: PendingHTLCsForwardable")
            
            let value = event.getValueAsPendingHtlcsForwardable()!
            let timeForwardable = value.getTimeForwardable()
            print("Forwarding in \(timeForwardable) seconds..")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Int(timeForwardable))) {
                print("Forwarding pending HTLCs..")
                self.processPendingHTLCForwards()
            }
        case .ChannelPending:
            print("\(instanceId) received LDK event: ChannelPending")
        case .SpendableOutputs:
            print("\(instanceId) received LDK event: SpendableOutputs")
            
//            if let outputDescriptor = event.getValueAsSpendableOutputs()?.getOutputs(),
//               let btcDepositAdapter = Container.bitcoinDepositAdapter(),
//               let changeDestinationScript = try? Address(address: btcDepositAdapter.receiveAddress).scriptPubkey().toBytes() {
//                
//                print("outputDescriptor \(outputDescriptor)")
//                
//                instance.handleSpendableOutputs(descriptors: outputDescriptor, changeDestinationScript: changeDestinationScript)
//            }
        case .PaymentForwarded:
            print("\(instanceId) received LDK event: PaymentForwarded")
        case .ChannelClosed:
            print("\(instanceId) received LDK event: ChannelClosed")
        case .DiscardFunding:
            print("\(instanceId) received LDK event: DiscardFunding")
        case .OpenChannelRequest:
            print("\(instanceId) received LDK event: OpenChannelRequest")
        case .HTLCHandlingFailed:
            print("\(instanceId) received LDK event: HTLCHandlingFailed")
        case .ChannelReady:
            print("\(instanceId) received LDK event: ChannelReady")
        case .HTLCIntercepted:
            print("\(instanceId) received LDK event: HTLC intercepted")
        case .InvoiceRequestFailed:
            print("\(instanceId) received LDK event: InvoiceRequestFailed")
        case .BumpTransaction:
            print("\(instanceId) received LDK event: BumpTransaction")
        @unknown default:
            print("\(instanceId) received LDK event: default event")

        }
    }
    
    private func processPendingHTLCForwards() {
        channelManager.processPendingHtlcForwards()
    }
    
    private func claimFunds(preimage: [UInt8]) {
        channelManager.claimFunds(paymentPreimage: preimage)
    }
    
    private func subscribeToChainPublisher() throws {
        rpcInterface.blockchainMonitorPublisher
            .sink(receiveCompletion: { error in
                print("Error subscribing to blockchain monitor")
            }, receiveValue: { [unowned self] _ in
                let bestBLockHeight = channelManagerConstructor.channelManager.currentBestBlock().height()
                print("LDK CHANNEL MANAGER BEST BLOCK: \(bestBLockHeight)\n")
            })
            .store(in: &cancellables)
    }
    
    private func subscribeToNodeEvents() throws {
        channelManagerAndNetworkGraphPersisterAndEventHandler.onNodeEventUpdate
            .sink { [unowned self] event in
                handleNodeEvent(event)
            }
            .store(in: &cancellables)
    }
    
    func openChannel() async throws {
        guard let lndPubkey = Utils.hexStringToBytes(hexString: ldnPeerProps.pubKey) else {
            throw TestFlowExceptions.hexParsingError
        }
        
        print("\(instanceId) connecting to playnet peer: \(ldnPeerProps.pubKey)")
        
        guard tcpPeerHandler.connect(address: ldnPeerProps.address, port: ldnPeerProps.port, theirNodeId: lndPubkey) else {
            throw TestFlowExceptions.failedToConnectToAlice
        }
        
        print("\(instanceId) connected to: \(ldnPeerProps.pubKey)")

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
        
        let channelOpenResult = channelManager.createChannel(
            theirNetworkKey: lndPubkey,
            channelValueSatoshis: channelValue,
            pushMsat: reserveAmount,
            userChannelId: userChannelId,
            overrideConfig: config
        )

        if let channelOpenError = channelOpenResult.getError() {
            print("\(instanceId) error type: \(channelOpenError.getValueType())")
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
        let _ = try await rpcInterface.mineBlocks(number: 4, coinbaseDestinationAddress: fAddress)
        
        var usableChannels = [ChannelDetails]()
        while (usableChannels.isEmpty) {
            usableChannels = channelManager.listUsableChannels()
            // sleep for 100ms
            try await Task.sleep(nanoseconds: 0_100_000_000)
        }
                
        let events = await channelManagerAndNetworkGraphPersisterAndEventHandler.getManagerEvents(expectedCount: 2)
        let channelPendingEvent = events[0]
        let channelReadyEvent = events[1]
        
        guard (channelPendingEvent.getValueAsChannelPending() != nil) else {
            throw TestFlowExceptions.unexpectedChannelManagerEventType
        }
        
        guard (channelReadyEvent.getValueAsChannelReady() != nil) else {
            throw TestFlowExceptions.unexpectedChannelManagerEventType
        }
        
        let channel = usableChannels.first!
        let channelId = channel.getChannelId()!.toHexString()
        let channeValueSats = channel.getChannelValueSatoshis()
        let channeBalanceMsats = channel.getBalanceMsat()
        let channeIsUsable = channel.getIsUsable()
        let channelIsReady = channel.getIsChannelReady()
        let channelIsOnbound = channel.getIsOutbound()
        let channelInboundCapacityMsats = channel.getInboundCapacityMsat()
        let channelOutboundCapacityMsats = channel.getOutboundCapacityMsat()
        
        print("=========================================")
        print("Channel \(channelId) \(channelIsReady ? "ready" : "not ready"), \(channeIsUsable ? "usable" : "unusable"), is onbound: \(channelIsOnbound)")
        print(String())
        print("channeValueSats \(channeValueSats)")
        print("channeBalanceMsats \(channeBalanceMsats)")
        print("channelInboundCapacityMsats \(channelInboundCapacityMsats)")
        print("channelOutboundCapacityMsats \(channelOutboundCapacityMsats)")
        print("=========================================")
    }
    
    func createHodlInvoice(secretHash: String, satAmount: UInt64, description: String) -> Promise<String> {
        Promise { [unowned self] resolve, reject in
            guard let channelManager = channelManager else {
                return reject(NodeError.failedObtainChannelManager)
            }
            guard let keyInterface = keysManager else {
                return reject(NodeError.failedObtainKeyManager)
            }
                        
            let createInvoiceWithPaymentHashResult = Bindings.createInvoiceFromChannelmanagerAndDurationSinceEpochWithPaymentHash(
                channelmanager: channelManager,
                nodeSigner: keyInterface.asNodeSigner(),
                logger: logger,
                network: .Regtest,
                amtMsat: satAmount * 1000,
                description: description,
                durationSinceEpoch: UInt64(Date().timeIntervalSince1970),
                invoiceExpiryDeltaSecs: 86400,
                paymentHash: secretHash.hexToBytes(),
                minFinalCltvExpiryDelta: nil
            )
            
            guard
                createInvoiceWithPaymentHashResult.isOk(),
                let invoice = createInvoiceWithPaymentHashResult.getValue()
            else {
                if let errorMsg = createInvoiceWithPaymentHashResult.getError()?.toStr() {
                    return reject(NodeError.msg(errorMsg))
                } else {
                    return reject(NodeError.msg("Cannot create invoice"))
                }
            }
                        
            let holdlInvoice = HodlInvoice(
                id: secretHash,
                description: description,
                tokens: satAmount,
                paymentRequest: invoice.toStr()
            )
            
            hodlInvoices.append(holdlInvoice)
            
            resolve(holdlInvoice.paymentRequest)
        }
    }
    
    func payHodlInvoice(swapId: String, request: String) async throws -> PaymentResult {
        guard let manager = channelManager else {
            throw NodeError.msg("No payer")
        }
        
        let decodingInvoiceResult = Bindings.Bolt11Invoice.fromStr(s: request)
        
        guard decodingInvoiceResult.isOk(), let invoice = decodingInvoiceResult.getValue() else {
            if let error = decodingInvoiceResult.getError() {
                throw NodeError.msg(error.toStr())
            } else {
                throw NodeError.msg("Cannot decode invoice")
            }
        }
                    
        let paymentResult = Bindings.payInvoice(invoice: invoice, retryStrategy: .initWithAttempts(a: 3), channelmanager: manager)
            
        guard paymentResult.isOk() else {
            if let invoicePayError = paymentResult.getError() {
                if let error = invoicePayError.getValueAsInvoice() {
                    print("Invoice error: \(error)")
                    throw NodeError.msg("Invoice error: \(error)")
                } else if let error = invoicePayError.getValueAsSending() {
                    print("Sending error")
                    switch error {
                    case .RouteNotFound:
                        print("RouteNotFound")
                        throw NodeError.msg("RouteNotFound")
                    case .DuplicatePayment:
                        print("DuplicatePayment")
                        throw NodeError.msg("DuplicatePayment")
                    case .PaymentExpired:
                        print("PaymentExpired")
                        throw NodeError.msg("PaymentExpired")
                    @unknown default:
                        print("Unknown invoice paer error")
                        throw NodeError.msg("Unknown invoice payer error")
                    }
                } else {
                    print("Unknown error")
                    throw NodeError.msg("unknown error")
                }
            } else {
                throw NodeError.msg("unknown error")
            }
        }
                
        let pendingPayments = channelManager.listRecentPayments().filter { payment in
            let value = payment.getValueType()
            return value == .Pending
        }
                
        let paymentWithSameAmount = pendingPayments.first { payment in
            let value = payment.getValueAsPending()!
            print("Invoice amount: \(String(describing: invoice.amountMilliSatoshis()))")
            print("Pending payment amount: \(value.getTotalMsat())")
            return value.getTotalMsat() == invoice.amountMilliSatoshis()
        }
        
        guard let pendingPayment = paymentWithSameAmount else {
            throw NodeError.msg("Cannot find a pending payment with same ammount")
        }
        
        let type = pendingPayment.getValueAsPending()!
        print("HodlInvoice payment is pending, paymentHash: \(type.getPaymentHash().toHexString())")
        
        let paymentHash = type.getPaymentHash()
        
        return PaymentResult(
            id: paymentHash.toHexString(),
            swap: PaymentResult.Swap(id: swapId),
            request: request,
            amount: Int64((invoice.amountMilliSatoshis() ?? 0)) * 1000
        )
    }
    
    func pay(swapId: String, request: String) async throws -> PaymentResult {
        guard let manager = channelManager else {
            throw NodeError.msg("No payer")
        }
        
        let decodingInvoiceResult = Bindings.Bolt11Invoice.fromStr(s: request)
        
        guard decodingInvoiceResult.isOk(), let invoice = decodingInvoiceResult.getValue() else {
            if let error = decodingInvoiceResult.getError() {
                throw NodeError.msg(error.toStr())
            } else {
                throw NodeError.msg("Cannot decode invoice")
            }
        }
                    
        let paymentResult = Bindings.payInvoice(invoice: invoice, retryStrategy: .initWithAttempts(a: 3), channelmanager: manager)
            
        guard paymentResult.isOk() else {
            if let invoicePayError = paymentResult.getError() {
                if let error = invoicePayError.getValueAsInvoice() {
                    print("Invoice error: \(error)")
                    throw NodeError.msg("Invoice error: \(error)")
                } else if let error = invoicePayError.getValueAsSending() {
                    print("Sending error")
                    switch error {
                    case .RouteNotFound:
                        print("RouteNotFound")
                        throw NodeError.msg("RouteNotFound")
                    case .DuplicatePayment:
                        print("DuplicatePayment")
                        throw NodeError.msg("DuplicatePayment")
                    case .PaymentExpired:
                        print("PaymentExpired")
                        throw NodeError.msg("PaymentExpired")
                    @unknown default:
                        print("Unknown invoice paer error")
                        throw NodeError.msg("Unknown invoice payer error")
                    }
                } else {
                    print("Unknown error")
                    throw NodeError.msg("unknown error")
                }
            } else {
                throw NodeError.msg("unknown error")
            }
        }
        
        print("Payment sent. waiting confirmation event...")
        
        guard let event = await channelManagerAndNetworkGraphPersisterAndEventHandler.eventTracker.await(events: [.paymentFailed, .paymentSent], timeout: 5) else {
            throw NodeError.msg("Not received paymentFailed or paymentSent event. Timeout error")
        }
                
        switch event.getValueType() {
        case .PaymentSent:
            guard let paymentSent = event.getValueAsPaymentSent() else {
                throw NodeError.msg("getValueAsPaymentSent is nil")
            }
            
            let paymentHash = paymentSent.getPaymentHash()
            
            return PaymentResult(
                id: paymentHash.toHexString(),
                swap: PaymentResult.Swap(id: swapId),
                request: request,
                amount: Int64((invoice.amountMilliSatoshis() ?? 0)) * 1000
            )
        case .PaymentFailed:
            guard let paymentFailed = event.getValueAsPaymentFailed() else {
                throw NodeError.msg("getValueAsPaymentFailed is nil")
            }
            
            let errorMessage = "Payment failed:\nid: \(paymentFailed.getPaymentId().toHexString())\nhash: \(paymentFailed.getPaymentHash().toHexString())"
            print(errorMessage)
            
            throw NodeError.msg(errorMessage)
        default:
            throw NodeError.msg("Get wrond event: \(event.getValueType())")
        }
    }
    
    private func getMockAddress(rpcInterface: RegtestBlockchainManager) async throws -> String {
        let MOCK_OUTPUT_SCRIPT: [UInt8] = [0, 1, 0]
        let scriptDetails = try await rpcInterface.decodeScript(script: MOCK_OUTPUT_SCRIPT)
        let fakeAddress = ((scriptDetails["segwit"] as! [String: Any])["address"] as! String)
        return fakeAddress
    }
}

extension LdkNode: ILightningClient {
    func createHodlInvoice(hash: String, memo: String, quantity: Int64) -> Promise<String> {
        createHodlInvoice(secretHash: hash, satAmount: UInt64(quantity), description: memo)
    }
    
    func payViaPaymentRequest(swapId: String, request: String) -> Promise<PaymentResult> {
        Promise { [unowned self] resolve, reject in
            Task {
                do {
                    let paymentResult = try await payHodlInvoice(swapId: swapId, request: request)
                    resolve(paymentResult)
                } catch {
                    reject(error)
                }
            }
        }
    }
    
    func settleHodlInvoice(secret: Data) -> Promise<[String: String]> {
        Promise { [unowned self] resolve, reject in
            print("\(instanceId) settling invoice..")
            
            let secretHash = Utils.sha256(secret).toHexString()
            
            if let hodlInvoice = hodlInvoices.first(where: { $0.id == secretHash}) {
                let preimage: [UInt8] = Array(secret)
                claimFunds(preimage: preimage)
                
                print("\(instanceId) settled invoice, waiting Payment Claimed event...")
                resolve(["id": secretHash])
            } else {
                reject(NodeError.msg("Hodl invoice with id: \(secretHash) isn't exist"))
            }
        }
    }
    
    func subscribeToInvoice(id: String) -> Promise<InvoiceSubscription> {
        Promise { [unowned self] resolve, reject in
            guard let invoice = self.hodlInvoices.first(where: { $0.description == id }) else {
                return reject(NodeError.msg("Cannot find the invoice with id: \(id)"))
            }
            resolve(invoice.subscription)
        }
    }
}
