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

public struct BlockInfo {
    public let height: Int
    public let headerHash: String
}

class LightningKitManager: ILightningKitManager {
    private let instance: Node
    private let fileManager = LightningFileManager()
    private var started = false
    
    var allChannels: [ChannelDetails] {
        instance.allChannels
    }
    
    var usableChannels: [ChannelDetails] {
        instance.usableChannels
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
    
    var channelBalance: Decimal {
        Decimal(instance.totalBalance)
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
    
    func createInvoice(amount: String, description: String) async -> String? {
        if let amountDouble = Double(amount), amountDouble > 0 {
            let satAmountDouble = amountDouble * 100_000_000
            let satAmountInt = UInt64(satAmountDouble)
            return await instance.createInvoice(satAmount: satAmountInt, description: description)
        }
        return await instance.createInvoice(satAmount: nil, description: description)
    }
    
    func pay(invoice: String) -> Future<TransactionRecord, Error> {
        Future { [unowned self] promise in
            Task {
                do {
                    if let invoice = try self.decode(invoice: invoice) {
                        print("Invoice decoded")
                        
                        let paymentResult = try await self.instance.pay(invoice: invoice)
                        let transactionRecord = TransactionRecord(payment: paymentResult)
                        promise(.success(transactionRecord))
                    }
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
    
    func decode(invoice: String) throws -> Invoice? {
        try instance.decode(invoice: invoice)
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
                fundingTransaction: fundingTransaction
            ) {
                print("Channel \(channelInfo.temporaryChannelId) is opened")
            } else {
                throw ServiceError.cannotOpenChannel
            }
        }
    }
    
    private func handleNodeEvent(_ event: Event) {
        if let eventType = event.getValueType() {
            print("Received node event: \(eventType)")
        }
        
        if let type = event.getValueType() {
            switch type {
            case .PaymentPathSuccessful:
                print("PaymentPathSuccessful")                
            case .FundingGenerationReady:
                print("FundingGenerationReady")
            case .PaymentReceived:
                print("PaymentReceived:")
                let value = event.getValueAsPaymentReceived()!
                let amount = value.getAmount_msat()/1000
                print("Amount: \(amount)")
                let paymentId = value.getPayment_hash().toHexString()
                print("Payment \(paymentId) received ")
                    
                let paymentPurpose = value.getPurpose()
                let invoicePayment = paymentPurpose.getValueAsInvoicePayment()!
                let preimage = invoicePayment.getPayment_preimage()
                
                instance.claimFunds(preimage: preimage)
                
            case .PaymentClaimed:
                print("PaymentClaimed:")
                
                let value = event.getValueAsPaymentClaimed()!
                let amount = value.getAmount_msat()/1000
                print("Amount: \(amount)")
                let paymentId = value.getPayment_hash().toHexString()
                print("Payment \(paymentId) claimed")
                    
                let paymentPurpose = value.getPurpose()
                let invoicePayment = paymentPurpose.getValueAsInvoicePayment()!
                let preimage = invoicePayment.getPayment_preimage()
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
                
            case .PaymentSent:
                print("PaymentSent")
            case .PaymentFailed:
                print("PaymentFailed")
                
                let value = event.getValueAsPaymentFailed()!
                
                print("payment ID: \(value.getPayment_id().toHexString())")
                print("payment hash: \(value.getPayment_hash().toHexString())")

            case .PaymentPathFailed:
                print("PaymentPathFailed")
                
                let value = event.getValueAsPaymentPathFailed()!
                print("all paths failed - \(value.getAll_paths_failed() ? "yes" : "no")")
                for path in value.getPath() {
                    print("hop:")
                    print("node pubkey \(path.get_pubkey())")
                }
                print("is regected by destination: \(value.getRejected_by_dest() ? "yes" : "no")")
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
        } else {
            print("event \(event) doesnt contain value type")
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
    
    private func rawTx(amount: UInt64, address: String) throws -> [UInt8] {
        let adapterManager = Container.adapterManager()
        guard let adapter = adapterManager.adapter(for: .bitcoin()) as? ISendBitcoinAdapter else {
            throw ServiceError.keySeedNotFound
        }
        return try adapter.rawTransaction(amount: amount, address: address)
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
