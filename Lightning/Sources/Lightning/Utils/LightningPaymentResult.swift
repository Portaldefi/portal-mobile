//
//  File.swift
//  
//
//  Created by farid on 3/28/23.
//

import Foundation

public struct LightningPaymentResult {
    public let paymentID: String
    public let paymentHash: String
    public let preimage: String
    public let fee: UInt64
    
    public init(paymentID: String, paymentHash: String, preimage: String, fee: UInt64) {
        self.paymentID = paymentID
        self.paymentHash = paymentHash
        self.preimage = preimage
        self.fee = fee
    }
}
