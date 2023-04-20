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
    func pay(invoice: String) -> Combine.Future<TransactionRecord, Error>
}
