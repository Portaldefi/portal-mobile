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
    private let fileManager = LightningFileManager()
    private var started = false
        
    var transactionsPublisher: AnyPublisher<[TransactionRecord], Never> {
        let payments = fileManager.getPayments().map { payment in
            let source: TxSource = .lightning
            let data = txDataStorage.fetch(source: source, id: payment.paymentId)
            let userData = TxUserData(data: data)
            return TransactionRecord(payment: payment, userData: userData)
        }
        return Just(payments).eraseToAnyPublisher()
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
            await subscribeForNodeEvents()
        } catch {
            throw error
        }
    }
    
    func subscribeForNodeEvents() async {
        for await event in await instance.subscribeForNodeEvents() {
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
            let value = event.getValueAsPaymentClaimable()!
            let amount = value.getAmountMsat()/1000
            print("Amount: \(amount)")
            let paymentId = value.getPaymentHash().toHexString()
            print("Payment \(paymentId) received ")
                
            let paymentPurpose = value.getPurpose()
            let invoicePayment = paymentPurpose.getValueAsInvoicePayment()!
            let preimage = invoicePayment.getPaymentPreimage()
            
            instance.claimFunds(preimage: preimage)
            
        case .PaymentClaimed:
            print("PaymentClaimed:")
            
            let value = event.getValueAsPaymentClaimed()!
            let amount = value.getAmountMsat()/1000
            print("Amount: \(amount)")
            let paymentId = value.getPaymentHash().toHexString()
            print("Payment \(paymentId) claimed")
                
            let paymentPurpose = value.getPurpose()
            let invoicePayment = paymentPurpose.getValueAsInvoicePayment()!
            let preimage = invoicePayment.getPaymentPreimage()
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
            
            let btcAmount = Double(payment.amount) / Double(100_000_000)
            let message = "You've received \(btcAmount) BTC"
            
            let notification = PNotification(message: result)
            notificationService.notify(notification)
            
        case .PaymentSent:
            print("PaymentSent")
        case .PaymentFailed:
            print("PaymentFailed")
            
            let value = event.getValueAsPaymentFailed()!
            
            print("payment ID: \(value.getPaymentId().toHexString())")
            print("payment hash: \(value.getPaymentHash().toHexString())")

        case .PaymentPathFailed:
            print("PaymentPathFailed")
            
            let value = event.getValueAsPaymentPathFailed()!
            print("all paths failed - \(value.getPaymentFailedPermanently() ? "yes" : "no")")
            for path in value.getPath() {
                print("hop:")
                print("node pubkey \(path.getPubkey())")
            }
        case .ProbeSuccessful:
            print("ProbeSuccessful")

        case .ProbeFailed:
            print("ProbeFailed")

        case .PendingHTLCsForwardable:
            print("PendingHTLCsForwardable")
            
            instance.processPendingHTLCForwards()
        case .SpendableOutputs:
            print("SpendableOutputs")

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

        @unknown default:
            print("default event")

        }
    }
    
    private func generateKeySeed() {
        let seed = AES.randomIV(32)
        _ = fileManager.persistKeySeed(keySeed: seed)
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
    
    private func rawTx(amount: UInt64, address: String) throws -> Transaction {
        let adapterManager = Container.adapterManager()
        guard let adapter = adapterManager.adapter(for: .bitcoin()) as? ISendBitcoinAdapter else {
            throw ServiceError.keySeedNotFound
        }
        return try adapter.rawTransaction(amount: amount, address: address)
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
        if let amountDouble = Double(amount), amountDouble > 0 {
            let satAmountDouble = amountDouble * 100_000_000
            let satAmountInt = UInt64(satAmountDouble)
            return await instance.createInvoice(satAmount: satAmountInt, description: description)
        }
        return await instance.createInvoice(satAmount: nil, description: description)
    }
    
    func createInvoice(paymentHash: String, satAmount: UInt64) async -> Invoice? {
        await instance.createInvoice(paymentHash: paymentHash, satAmount: satAmount)
    }
    
    func pay(invoice: String) -> Combine.Future<TransactionRecord, Error> {
        Future { [unowned self] promise in
            Task {
                do {
                    if let invoice = try self.decode(invoice: invoice) {
                        print("Invoice decoded")
                        
                        let paymentResult = try await self.instance.pay(invoice: invoice)
                        let source: TxSource = .lightning
                        let data = txDataStorage.fetch(source: source, id: paymentResult.paymentId)
                        let userData = TxUserData(data: data)
                        let transactionRecord = TransactionRecord(payment: paymentResult, userData: userData)
                        promise(.success(transactionRecord))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    func pay(invoice: Invoice) async throws -> TransactionRecord {
        let paymentResult = try await self.instance.pay(invoice: invoice)
        let source: TxSource = .lightning
        let data = txDataStorage.fetch(source: source, id: paymentResult.paymentId)
        let userData = TxUserData(data: data)
        return TransactionRecord(payment: paymentResult, userData: userData)
    }
    
    func decode(invoice: String) throws -> Invoice? {
        try instance.decode(invoice: invoice)
    }
}

extension LightningKitManager: ILightningChannels {
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
    }
}
