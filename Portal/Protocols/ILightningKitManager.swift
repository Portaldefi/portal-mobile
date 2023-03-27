//
//  ILightningKitManager.swift
//  Portal
//
//  Created by farid on 2/27/23.
//

import Combine
import LightningDevKit

protocol ILightningKitManager {
    var channelBalance: Decimal { get }
    var activePeersPublisher: AnyPublisher<[String], Never> { get }
    func start() async throws
    func connectPeer(_ peer: Peer) async throws
    func createInvoice(amount: String, description: String) async -> String?
    func decode(invoice: String) throws -> Invoice?
    func pay(invoice: String) -> Future<TransactionRecord, Error>
}
