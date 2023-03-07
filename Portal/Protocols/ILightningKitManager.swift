//
//  ILightningKitManager.swift
//  Portal
//
//  Created by farid on 2/27/23.
//

import Combine

protocol ILightningKitManager {
    var activePeersPublisher: AnyPublisher<[String], Never> { get }
    func start() async throws
    func connectPeer(_ peer: Peer) async throws
    func requestChannelOpen(_ pubKeyHex: String, channelValue: UInt64, reserveAmount: UInt64) async throws -> String
    func createInvoice(amount: String, description: String) async -> String?
}
