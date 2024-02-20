//
//  ILightningKitManager.swift
//  Portal
//
//  Created by farid on 2/27/23.
//

import Combine
import LightningDevKit
import Lightning

protocol ILightningChannels {
    var allChannels: [ChannelDetails] { get }
    var usableChannels: [ChannelDetails] { get }
    var channelBalance: Decimal { get }
    func openChannel(peer: Peer, amount: UInt64) async throws
    func cooperativeCloseChannel(id: [UInt8], counterPartyId: [UInt8])
    func forceCloseChannel(id: [UInt8], counterPartyId: [UInt8])
}

protocol ILightningInvoiceHandler {
    func createInvoice(amount: String, description: String) async -> String?
    func decode(invoice: String) throws -> Bolt11Invoice
    func pay(invoice: Bolt11Invoice) async throws -> LightningPayment
    func createInvoice(paymentHash: String, satAmount: UInt64) async -> Bolt11Invoice?
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
    var peer: Peer? { get }
    var bestBlock: Int32 { get }
    var transactions: [LightningPayment] { get }
    var transactionsPublisher: AnyPublisher<[LightningPayment], Never> { get }
    var activePeersPublisher: AnyPublisher<[String], Never> { get }
    func start() async throws
}
