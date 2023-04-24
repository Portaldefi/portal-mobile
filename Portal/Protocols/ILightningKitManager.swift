//
//  ILightningKitManager.swift
//  Portal
//
//  Created by farid on 2/27/23.
//

import Combine
import LightningDevKit

protocol ILightningKitManager {
    var allChannels: [ChannelDetails] { get }
    var usableChannels: [ChannelDetails] { get }
    var transactionsPublisher: AnyPublisher<[TransactionRecord], Never> { get }
    var channelBalance: Decimal { get }
    var activePeersPublisher: AnyPublisher<[String], Never> { get }
    func start() async throws
    func openChannel(peer: Peer) async throws
    func connectPeer(_ peer: Peer) async throws
    func disconnectPeer(_ peer: Peer) throws
    func createInvoice(amount: String, description: String) async -> String?
    func decode(invoice: String) throws -> Invoice?
    func decodeAddress(outputScript: [UInt8]) async -> String?
    func getDescriptorInfo(descriptor: String) async throws -> String?
    func pay(invoice: String) -> Combine.Future<TransactionRecord, Error>
    func pay(invoice: Invoice) async throws -> TransactionRecord
    func scanTxOutSet(descriptor: String) async throws -> [String: Any]
    func createInvoice(paymentHash: String, satAmount: UInt64) async -> String?
    func generate(blocks: Int, toAddress: String) async throws -> [String]
    func broadcastTransaction(tx: [UInt8])
}
