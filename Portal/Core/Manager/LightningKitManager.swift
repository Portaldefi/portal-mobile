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
import Factory
import HsCryptoKit
import BitcoinDevKit

public struct BlockInfo {
    public let height: Int
    public let headerHash: String
}

class LightningKitManager: ILightningKitManager {
    @Injected(Container.notificationService) private var notificationService
    @Injected(Container.txDataStorage) private var txDataStorage
    
    private let instance: Node
    
    private var fileManager: LightningFileManager {
        instance.fileManager
    }
    
    private var started = false
    private var hodlInvoices = [HodlInvoice]()
    private var peer: Peer?
    private var subscriptions = Set<AnyCancellable>()
        
    var transactionsPublisher: AnyPublisher<[TransactionRecord], Never> {
        let payments = fileManager.getPayments().map { payment in
            let source: TxSource = .lightning
            let data = txDataStorage.fetch(source: source, id: payment.paymentId)
            let userData = TxUserData(data: data)
            return TransactionRecord(payment: payment, userData: userData)
        }
        return Just(payments).eraseToAnyPublisher()
    }
    
    var transactions: [TransactionRecord] {
        fileManager.getPayments().map { payment in
            let source: TxSource = .lightning
            let data = txDataStorage.fetch(source: source, id: payment.paymentId)
            let userData = TxUserData(data: data)
            return TransactionRecord(payment: payment, userData: userData)
        }
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
                        
            if let peerData = UserDefaults.standard.data(forKey: "NodeToConnect") {
                let decoder = JSONDecoder()
                if let peer = try? decoder.decode(Peer.self, from: peerData) {
                    self.peer = peer
                }
            }
            
            activePeersPublisher.sink { [unowned self] peerIDs in
                guard let peer = peer else { return }
                                
                if !peerIDs.contains(peer.peerPubKey) {
                    Task {
                        try? await instance.connectPeer(
                            pubKey: peer.peerPubKey,
                            hostname: peer.connectionInformation.hostname,
                            port: peer.connectionInformation.port
                        )
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                    }
                }
            }
            .store(in: &subscriptions)
            
            await subscribeForNodeEvents()
        } catch {
            throw error
        }
    }
    
    func subscribeForNodeEvents() async {
        for await event in await instance.subscribeForNodeEvents() {
            try? await Task.sleep(nanoseconds: 250_000)
            handleNodeEvent(event)
        }
    }
    
    private func handleNodeEvent(_ event: Event) {
        print("Received node event: \(event.getValueType())")
        
        switch event.getValueType() {
        case .PaymentPathSuccessful:
            print("PaymentPathSuccessful")
        case .FundingGenerationReady:
            print("FundingGenerationReady")
        case .PaymentClaimable:
            print("PaymentClaimable:")
            
            let paymentClaimableEvent = event.getValueAsPaymentClaimable()!
            let paymentHashData = paymentClaimableEvent.getPaymentHash()
            let paymentHashString = paymentHashData.toHexString()
            
            let paymentPurpose = paymentClaimableEvent.getPurpose()
            
            switch paymentPurpose.getValueType() {
            case .InvoicePayment:
                let invoicePayment = paymentPurpose.getValueAsInvoicePayment()!
                let paymentSecret = invoicePayment.getPaymentSecret()
                
                if let paymentPreimage = invoicePayment.getPaymentPreimage() {
                    instance.claimFunds(preimage: paymentPreimage)
                } else {
                    let getPaymentPreimageResult = instance.channelManager!.getPaymentPreimage(paymentHash: paymentHashData, paymentSecret: paymentSecret)
                    if getPaymentPreimageResult.isOk(), let paymentPreimage = getPaymentPreimageResult.getValue() {
                        instance.claimFunds(preimage: paymentPreimage)
                    } else {
                        if let hodlInvoice = hodlInvoices.first(where: { $0.id == paymentHashString}) {
                            print("Received Payment Claimable for Hodl invoice with id: \(hodlInvoice.id)")
                            hodlInvoice.update(status: .paymentHeld)
                        } else {
                            print("Received claimable event with unknown preimage, cannot claim")
                        }
                    }
                }
            case .SpontaneousPayment:
                print("SpontaneousPayments not handled yet")
            @unknown default:
                print("Unknown payment purpose")
                break
            }
        case .PaymentClaimed:
            print("PaymentClaimed:")
            
            let value = event.getValueAsPaymentClaimed()!
            let amount = value.getAmountMsat()/1000
            print("Amount: \(amount)")
            let paymentId = value.getPaymentHash().toHexString()
            print("Payment \(paymentId) claimed")
            
            if let hodlInvoice = hodlInvoices.first(where: { $0.id == paymentId}) {
                hodlInvoice.update(status: .paymentConfirmed)
            }
                
            let paymentPurpose = value.getPurpose()
            let invoicePayment = paymentPurpose.getValueAsInvoicePayment()!
            let preimage = invoicePayment.getPaymentPreimage() ?? [UInt8]()
            let timestamp = Int(Date().timeIntervalSince1970)
            
            let payment = LightningPayment(
                nodeId: nil,
                paymentId: paymentId,
                amount: amount,
                preimage: preimage.toHexString(),
                type: .received,
                timestamp: timestamp,
                fee: nil
            )
                            
            switch fileManager.persist(payment: payment) {
            case .success:
                print("payment \(paymentId) persisted")
            case .failure(let error):
                print("Unable to persist payment \(paymentId)")
                print("ERROR: \(error.localizedDescription)")
            }
            
//            let btcAmount = Double(payment.amount) / Double(100_000_000)
//            let message = "You've received \(btcAmount) BTC"
//            
//            let notification = PNotification(message: message)
//            notificationService.notify(notification)
            
        case .PaymentSent:
            print("PaymentSent")
            
            let paymentSentEvent = event.getValueAsPaymentSent()!
            let paymentID = paymentSentEvent.getPaymentId()!.toHexString()
            let preimage = paymentSentEvent.getPaymentPreimage()
            let fee = paymentSentEvent.getFeePaidMsat()
            
            guard let pendingPayment = instance.pendingPayments.first(where: { $0.paymentId == paymentID }) else {
                print("There is no pending payment for event")
                return
            }
            
            let updatedPayment = LightningPayment(
                nodeId: pendingPayment.nodeId,
                paymentId: pendingPayment.paymentId,
                amount: pendingPayment.amount,
                preimage: preimage.toHexString(),
                type: .sent,
                timestamp: pendingPayment.timestamp,
                fee: fee
            )
            
            switch fileManager.persist(payment: updatedPayment) {
            case .success:
                print("payment \(paymentID) persisted")
            case .failure(let error):
                print("Unable to persist payment \(paymentID): \(error.localizedDescription)")
            }
        case .PaymentFailed:
            print("PaymentFailed")
            
            let value = event.getValueAsPaymentFailed()!
            
            print("payment ID: \(value.getPaymentId().toHexString())")
            print("payment hash: \(value.getPaymentHash().toHexString())")

        case .PaymentPathFailed:
            print("PaymentPathFailed")
            
            let value = event.getValueAsPaymentPathFailed()!
            print("all paths failed - \(value.getPaymentFailedPermanently() ? "yes" : "no")")
        case .ProbeSuccessful:
            print("ProbeSuccessful")

        case .ProbeFailed:
            print("ProbeFailed")

        case .PendingHTLCsForwardable:
            print("PendingHTLCsForwardable")
            
            instance.processPendingHTLCForwards()
        case .SpendableOutputs:
            print("SpendableOutputs")
            
            if let outputDescriptor = event.getValueAsSpendableOutputs()?.getOutputs(),
               let btcDepositAdapter = Container.bitcoinDepositAdapter(),
               let changeDestinationScript = try? Address(address: btcDepositAdapter.receiveAddress).scriptPubkey().toBytes() {
                
                print("outputDescriptor \(outputDescriptor)")
                
                instance.handleSpendableOutputs(descriptors: outputDescriptor, changeDestinationScript: changeDestinationScript)
            }
        case .PaymentForwarded:
            print("PaymentForwarded")
        case .ChannelClosed:
            print("ChannelClosed")
        case .DiscardFunding:
            print("DiscardFunding")
        case .OpenChannelRequest:
            print("OpenChannelRequest")
        case .HTLCHandlingFailed:
            print("HTLCHandlingFailed")
        case .InvoiceRequestFailed:
            print("InvoiceRequestFailed")
        case .HTLCIntercepted:
            print("HTLCIntercepted")
        case .ChannelPending:
            print("ChannelPending")
        case .ChannelReady:
            print("ChannelReady")
        case .BumpTransaction:
            print("BumpTransaction")
        @unknown default:
            print("default event")

        }
    }
    
    private func generateKeySeed() {
        let seed = AES.randomIV(32)
        _ = fileManager.persistKeySeed(keySeed: seed)
    }
    
    private func rawTx(amount: UInt64, address: String) throws -> Transaction {
        let adapterManager = Container.adapterManager()
        guard let adapter = adapterManager.adapter(for: .bitcoin()) as? ISendBitcoinAdapter else {
            throw ServiceError.keySeedNotFound
        }
        return try adapter.rawTransaction(amount: amount, address: address)
    }
    
    private func payHodlInvoice(swapId: String, request: String) async throws -> PaymentResult {
        guard let manager = instance.channelManager else {
            throw ServiceError.msg("No payer")
        }
        
        let decodingInvoiceResult = Bindings.Bolt11Invoice.fromStr(s: request)
        
        guard decodingInvoiceResult.isOk(), let invoice = decodingInvoiceResult.getValue() else {
            if let error = decodingInvoiceResult.getError() {
                throw ServiceError.msg(error.toStr())
            } else {
                throw ServiceError.msg("Cannot decode invoice")
            }
        }
                    
        let paymentResult = Bindings.payInvoice(invoice: invoice, retryStrategy: .initWithAttempts(a: 3), channelmanager: manager)
            
        guard paymentResult.isOk() else {
            if let invoicePayError = paymentResult.getError() {
                if let error = invoicePayError.getValueAsInvoice() {
                    print("Invoice error: \(error)")
                    throw ServiceError.msg("Invoice error: \(error)")
                } else if let error = invoicePayError.getValueAsSending() {
                    print("Sending error")
                    switch error {
                    case .RouteNotFound:
                        print("RouteNotFound")
                        throw ServiceError.msg("RouteNotFound")
                    case .DuplicatePayment:
                        print("DuplicatePayment")
                        throw ServiceError.msg("DuplicatePayment")
                    case .PaymentExpired:
                        print("PaymentExpired")
                        throw ServiceError.msg("PaymentExpired")
                    @unknown default:
                        print("Unknown invoice paer error")
                        throw ServiceError.msg("Unknown invoice payer error")
                    }
                } else {
                    print("Unknown error")
                    throw ServiceError.msg("unknown error")
                }
            } else {
                throw ServiceError.msg("unknown error")
            }
        }
                
        let pendingPayments = manager.listRecentPayments().filter { payment in
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
            throw ServiceError.msg("Cannot find a pending payment with same ammount")
        }
        
        let type = pendingPayment.getValueAsPending()!
        print("HodlInvoice payment is pending, paymentHash: \(type.getPaymentHash().toHexString())")
        
        let paymentID = type.getPaymentId()
        let paymentHash = type.getPaymentHash()
        let totalAmountMsat = type.getTotalMsat()
        
        let timestamp = Int(Date().timeIntervalSince1970)
        
        let payment = LightningPayment(
            nodeId: instance.channelManager?.getOurNodeId().toHexString() ?? "-",
            paymentId: paymentID.toHexString(),
            amount: totalAmountMsat/1000,
            preimage: String(),
            type: .sent,
            timestamp: timestamp,
            fee: nil
        )
        
        instance.pendingPayments.append(payment)
        
        return PaymentResult(
            id: paymentHash.toHexString(),
            swap: PaymentResult.Swap(id: swapId),
            request: request,
            amount: Int64((invoice.amountMilliSatoshis() ?? 0)) * 1000
        )
    }
}

extension LightningKitManager: IBitcoinCore {
    func broadcastTransaction(tx: [UInt8]) {
        instance.broacastTransaction(tx: tx)
    }
        
    func decodeAddress(outputScript: [UInt8]) async -> String? {
        await instance.decodeAddress(outputScript: outputScript)
    }
    
    func getDescriptorInfo(descriptor: String) async throws -> String? {
        try await instance.getDescriptorInfo(descriptor: descriptor)
    }
    
    func scanTxOutSet(descriptor: String) async throws -> [String: Any] {
        try await instance.scanTxOutSet(descriptor: descriptor)
    }
    
    func generate(blocks: Int, toAddress: String) async throws -> [String] {
        try await instance.generate(blocks: blocks, toAddress: toAddress)
    }
}

extension LightningKitManager: ILightningPeerHandler {
    func connectPeer(_ peer: Peer) async throws {
        try await instance.connectPeer(
            pubKey: peer.peerPubKey,
            hostname: peer.connectionInformation.hostname,
            port: peer.connectionInformation.port
        )
    }
    
    func disconnectPeer(_ peer: Peer) throws {
        try instance.disconnectPeer(pubKey: peer.peerPubKey)
    }
}

extension LightningKitManager: ILightningInvoiceHandler {
    func createInvoice(amount: String, description: String) async -> String? {
        let satoshiPerBitcoin: Decimal = 100_000_000

        if let amountDecimal = Decimal(string: amount), amountDecimal > 0 {
            let satAmountDecimal = amountDecimal * satoshiPerBitcoin
            let satAmountInt = NSDecimalNumber(decimal: satAmountDecimal).uint64Value
            return await instance.createInvoice(satAmount: satAmountInt, description: description)
        }
        return await instance.createInvoice(satAmount: nil, description: description)
    }
    
    func createInvoice(paymentHash: String, satAmount: UInt64) async -> Bolt11Invoice? {
        await instance.createInvoice(paymentHash: paymentHash, satAmount: satAmount)
    }
    
    func pay(invoice: String) async throws -> TransactionRecord {
        let decodedInvoice = try decode(invoice: invoice)
        return try await pay(invoice: decodedInvoice)
    }
    
    func pay(invoice: Bolt11Invoice) async throws -> TransactionRecord {
        let paymentResult = try await instance.pay(invoice: invoice)
        let source: TxSource = .lightning
        let data = txDataStorage.fetch(source: source, id: paymentResult.paymentId)
        let userData = TxUserData(data: data)
        return TransactionRecord(payment: paymentResult, userData: userData)
    }
    
    func decode(invoice: String) throws -> Bolt11Invoice {
        try instance.decode(invoice: invoice)
    }
}

extension LightningKitManager: ILightningChannels {
    func cooperativeCloseChannel(id: [UInt8], counterPartyId: [UInt8]) {
        instance.cooperativeCloseChannel(id: id, counterPartyId: counterPartyId)
    }
    
    func forceCloseChannel(id: [UInt8], counterPartyId: [UInt8]) {
        instance.forceCloseChannel(id: id, counterPartyId: counterPartyId)
    }
    
    var allChannels: [ChannelDetails] {
        instance.allChannels
    }
    
    var usableChannels: [ChannelDetails] {
        instance.usableChannels
    }
    
    var activePeersPublisher: AnyPublisher<[String], Never> {
        instance.connectedPeers
    }
    
    var channelBalance: Decimal {
        Decimal(instance.totalBalance)
    }
    
    func openChannel(peer: Peer) async throws {
        print("opening channel with peer: \(peer.peerPubKey)")
        
        let channelValue: UInt64 = 2500000
        let reserveAmount: UInt64 = 1000
        // send open channel request through channel manager
        let channelInfo = try await instance.requestChannelOpen(
            peer.peerPubKey,
            channelValue: channelValue,
            reserveAmount: reserveAmount
        )
        
        print("open channel requested")
        // decode output script
        if let address = await instance.getFundingTransactionScriptPubKey(outputScript: channelInfo.fundingOutputScript) {
            print("decoded address: \(address)")
            // create funding transaction
            let fundingTransaction = try rawTx(amount: channelValue, address: address)
            // finilaze opening channel by providing funding transaction to channel manager
            if try await instance.openChannel(
                channelOpenInfo: channelInfo,
                fundingTransaction: fundingTransaction.serialize()
            ) {
                print("Channel \(channelInfo.temporaryChannelId) is opened")
            } else {
                throw ServiceError.cannotOpenChannel
            }
        } else {
            throw NodeError.noRpcInterface
        }
    }
    
    func openChannel(peer: Peer, amount: UInt64) async throws {
        print("opening channel with peer: \(peer.peerPubKey)")
        
        let reserveAmount: UInt64 = 1000
        // send open channel request through channel manager
        let channelInfo = try await instance.requestChannelOpen(
            peer.peerPubKey,
            channelValue: amount,
            reserveAmount: reserveAmount
        )
        
        print("open channel requested")
        // decode output script
        if let address = await instance.getFundingTransactionScriptPubKey(outputScript: channelInfo.fundingOutputScript) {
            print("decoded address: \(address)")
            // create funding transaction
            let fundingTransaction = try rawTx(amount: amount, address: address)
            // finilaze opening channel by providing funding transaction to channel manager
            if try await instance.openChannel(
                channelOpenInfo: channelInfo,
                fundingTransaction: fundingTransaction.serialize()
            ) {
                print("Channel \(channelInfo.temporaryChannelId) is opened")
            } else {
                throw ServiceError.cannotOpenChannel
            }
        } else {
            throw NodeError.error("Cannot get funding tx script pub key")
        }
        
    }
}

import PortalSwapSDK
import Promises
import CryptoSwift

extension LightningKitManager: ILightningClient {
    func createHodlInvoice(hash: String, memo: String, quantity: Int64) -> Promise<String> {
        Promise { [unowned self] resolve, reject in
            guard let channelManager = instance.channelManager else {
                return reject(ServiceError.failedObtainChannelManager)
            }
            guard let keyInterface = instance.keysManager else {
                return reject(ServiceError.failedObtainKeyManager)
            }
            
            let satAmount = UInt64(quantity)
                        
            let createInvoiceWithPaymentHashResult = Bindings.createInvoiceFromChannelmanagerAndDurationSinceEpochWithPaymentHash(
                channelmanager: channelManager,
                nodeSigner: keyInterface.asNodeSigner(),
                logger: instance.logger,
                network: .Regtest,
                amtMsat: satAmount * 1000,
                description: memo,
                durationSinceEpoch: UInt64(Date().timeIntervalSince1970),
                invoiceExpiryDeltaSecs: 86400,
                paymentHash: hash.hexToBytes(),
                minFinalCltvExpiryDelta: nil
            )
            
            guard
                createInvoiceWithPaymentHashResult.isOk(),
                let invoice = createInvoiceWithPaymentHashResult.getValue()
            else {
                if let errorMsg = createInvoiceWithPaymentHashResult.getError()?.toStr() {
                    return reject(ServiceError.msg(errorMsg))
                } else {
                    return reject(ServiceError.msg("Cannot create invoice"))
                }
            }
                        
            let holdlInvoice = HodlInvoice(
                id: hash,
                description: memo,
                tokens: satAmount,
                paymentRequest: invoice.toStr()
            )
            
            hodlInvoices.append(holdlInvoice)
            
            resolve(holdlInvoice.paymentRequest)
        }
    }
    
    func subscribeToInvoice(id: String) -> Promise<InvoiceSubscription> {
        Promise { [unowned self] resolve, reject in
            guard let invoice = self.hodlInvoices.first(where: { $0.description == id }) else {
                return reject(ServiceError.msg("Cannot find the invoice with id: \(id)"))
            }
            resolve(invoice.subscription)
        }
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
    
    func settleHodlInvoice(secret: Data) -> Promise<[String : String]> {
        Promise { [unowned self] resolve, reject in
            print("settling invoice..")
            
            let secretHash = secret.sha256().toHexString()
            
            if let hodlInvoice = hodlInvoices.first(where: { $0.id == secretHash}) {
                let preimage: [UInt8] = Array(secret)
                instance.claimFunds(preimage: preimage)
                
                print("settled invoice, waiting Payment Claimed event...")
                resolve(["id": secretHash])
            } else {
                reject(ServiceError.msg("Hodl invoice with id: \(secretHash) isn't exist"))
            }
        }
    }
}

// MARK: Errors
extension LightningKitManager {
    public enum ServiceError: Error {
        case alreadyRunning
        case invalidHash
        case cannotOpenChannel
        case keySeedNotFound
        case invoicePaymentFailed
        case invalidInvoice
        case failedObtainKeyManager
        case failedObtainChannelManager
        case msg(String)
    }
}
