//
//  LightningPayment.swift
//  
//
//  Created by farid on 3/28/23.
//

import Foundation

public struct LightningPayment: Codable {
    public enum `Type`: Codable { case sent, received }
    
    public let nodeId: String?
    public let paymentId: String
    public let amount: UInt64
    public let preimage: String
    public let type: Type
    public let timestamp: Int
    public let fee: UInt64?
    public let memo: String?
    
    public init(nodeId: String?, paymentId: String, amount: UInt64, preimage: String, type: Type, timestamp: Int, fee: UInt64?, memo: String?) {
        self.nodeId = nodeId
        self.paymentId = paymentId
        self.amount = amount
        self.preimage = preimage
        self.type = type
        self.timestamp = timestamp
        self.fee = fee
        self.memo = memo
    }
}

