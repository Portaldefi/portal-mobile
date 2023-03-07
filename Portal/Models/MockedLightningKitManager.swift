//
//  MockedLightningKitManager.swift
//  Portal
//
//  Created by farid on 2/27/23.
//

import Combine

class MockedLightningKitManager: ILightningKitManager {
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
