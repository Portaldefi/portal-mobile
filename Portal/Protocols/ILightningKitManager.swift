//
//  ILightningKitManager.swift
//  Portal
//
//  Created by farid on 2/27/23.
//

import Combine
import LightningDevKit

protocol ILightningChannels {
    var allChannels: [ChannelDetails] { get }
    var usableChannels: [ChannelDetails] { get }
    var channelBalance: Decimal { get }
    func openChannel(peer: Peer) async throws
}

protocol ILightningInvoiceHandler {
    func createInvoice(amount: String, description: String) async -> String?
    func decode(invoice: String) throws -> Invoice?
    func pay(invoice: String) -> Combine.Future<TransactionRecord, Error>
    func pay(invoice: Invoice) async throws -> TransactionRecord
    func createInvoice(paymentHash: String, satAmount: UInt64) async -> Invoice?
}

protocol ILightningPeerHandler {
    func connectPeer(_ peer: Peer) async throws
    func disconnectPeer(_ peer: Peer) throws
}

protocol IBitcoinCore {
    func decodeAddress(outputScript: [UInt8]) async -> String?
    func getDescriptorInfo(descriptor: String) async throws -> String?
    func scanTxOutSet(descriptor: String) async throws -> [String: Any]
    func generate(blocks: Int, toAddress: String) async throws -> [String]
    func broadcastTransaction(tx: [UInt8])
}

protocol ILightningKitManager: ILightningChannels, ILightningInvoiceHandler, ILightningPeerHandler, IBitcoinCore {
    var transactionsPublisher: AnyPublisher<[TransactionRecord], Never> { get }
    var activePeersPublisher: AnyPublisher<[String], Never> { get }
    func start() async throws
}
