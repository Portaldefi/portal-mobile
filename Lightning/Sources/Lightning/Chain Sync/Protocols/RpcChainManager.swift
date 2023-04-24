//
//  RpcChainManager.swift
//  A protocol that establishes a contract for environment-agnostic chain interactions.
//
//  Created by Jurvis on 9/5/22.
//

import Foundation
import Combine

protocol RpcChainManager {
    var blockchainMonitorPublisher: AnyPublisher<Void, Error> { get }
    
    func registerListener(_ listener: ChainListener)
    func submitTransaction(transaction: [UInt8]) async throws -> String
    func getChaintipHeight() async throws -> UInt32
    func getChaintipHash() async throws -> [UInt8]
    func isMonitoring() async -> Bool
    
    func getTransaction(with hash: String) async throws -> [UInt8]
    func decodeScript(script: [UInt8]) async throws -> [String: Any]
    func getDescriptorInfo(descriptor: String) async throws -> String
    func scanTxOutSet(descriptor: String) async throws -> [String: Any]
    func mineBlocks(number: Int, coinbaseDestinationAddress: String) async throws -> [String]
}
