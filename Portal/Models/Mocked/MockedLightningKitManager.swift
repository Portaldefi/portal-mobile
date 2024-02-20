//
//  MockedLightningKitManager.swift
//  Portal
//
//  Created by farid on 2/27/23.
//

import Combine
import LightningDevKit
import Lightning

class MockedLightningKitManager: ILightningKitManager {
    var bestBlock: Int32 = 0
    
    var peer: Peer?
    
    func cooperativeCloseChannel(id: [UInt8], counterPartyId: [UInt8]) {
        
    }
    
    func forceCloseChannel(id: [UInt8], counterPartyId: [UInt8]) {
        
    }
    
    var transactions = [LightningPayment]()
    
    func createInvoice(paymentHash: String, satAmount: UInt64) async -> LightningDevKit.Bolt11Invoice? {
        nil
    }
    
    func broadcastTransaction(tx: [UInt8]) {
        
    }
    
    func generate(blocks: Int, toAddress: String) async throws -> [String] {
        []
    }
    
    func pay(invoice: Bolt11Invoice) async throws -> LightningPayment {
        LightningPayment.init(nodeId: nil, paymentId: UUID().uuidString, amount: 10000, preimage: String(), type: .sent, timestamp: 123876123, fee: 0, memo: "Mocked")
    }
    
    func createInvoice(paymentHash: String, satAmount: UInt64) async -> String? {
        nil
    }
    
    func scanTxOutSet(descriptor: String) async throws -> [String : Any] {
        [:]
    }
    
    func getDescriptorInfo(descriptor: String) async throws -> String? {
        nil
    }
    
    func decodeAddress(outputScript: [UInt8]) async -> String? {
        nil
    }
    
    func disconnectPeer(_ peer: Peer) throws {
        
    }
    
    var allChannels: [LightningDevKit.ChannelDetails] = []
    
    var usableChannels: [LightningDevKit.ChannelDetails] = []
    
    func openChannel(peer: Peer, amount: UInt64) async throws {
        
    }
    
    func openChannel(peer: Peer) async throws {
        
    }
    
    var transactionsPublisher: AnyPublisher<[LightningPayment], Never> {
        Just([]).eraseToAnyPublisher()
    }
    
    func pay(invoice: String) async throws -> TransactionRecord {
        .mocked(confirmed: true)
    }
    
    var channelBalance: Decimal {
        Decimal(10000)
    }
    
    func decode(invoice: String) throws -> Bolt11Invoice {
        if let invoice = Bolt11Invoice.fromStr(s: "lntb255m1p3l3qgadqqnp4qffgdax9g9ux3496d809u6le05nffsccvyuhdyvu5uumvyt7j5twkpp55eham28a4cnwz3epal2geeceskmjs6pxph987shgj3ydnv0nnqvssp5u8meh0nx9jaz68n97h3c22vxvmla2yynjgtcccpu5f4pjt7u7eps9qyysgqcqpcxqzlgsjl4nkpvgu4x54unwafr3s0h2mjtakw9cdklsa28qqdhmsxuqphhytyxlzwfx08nuwez5qvrvcfvkdgwdurtn67cr4l9wkdd6yu8rqgp88xwlu").getValue() {
            return invoice
        } else {
            throw SendFlowError.error("Decode invoice error")
        }
    }
    
    var activePeersPublisher: AnyPublisher<[String], Never> {
        Just([]).eraseToAnyPublisher()
    }
    
    func generateKeySeed() {
        
    }
    
    func start() async throws {
        
    }
    
    func connectPeer(_ peer: Peer) async throws {
        
    }
    
    func requestChannelOpen(_ pubKeyHex: String, channelValue: UInt64, reserveAmount: UInt64) async throws -> String {
        String()
    }
    
    func createInvoice(amount: String, description: String) async -> String? {
        "lntb255m1p3l3qgadqqnp4qffgdax9g9ux3496d809u6le05nffsccvyuhdyvu5uumvyt7j5twkpp55eham28a4cnwz3epal2geeceskmjs6pxph987shgj3ydnv0nnqvssp5u8meh0nx9jaz68n97h3c22vxvmla2yynjgtcccpu5f4pjt7u7eps9qyysgqcqpcxqzlgsjl4nkpvgu4x54unwafr3s0h2mjtakw9cdklsa28qqdhmsxuqphhytyxlzwfx08nuwez5qvrvcfvkdgwdurtn67cr4l9wkdd6yu8rqgp88xwlu"
    }
}
