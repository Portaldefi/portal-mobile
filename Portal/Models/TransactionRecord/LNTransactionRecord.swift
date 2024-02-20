//
//  LNTransactionRecord.swift
//  Portal
//
//  Created by farid on 12.01.2024.
//

import Foundation
import Lightning
import LightningDevKit

class LNTransactionRecord: TransactionRecord {
    let sender: String?
    let receiver: String?
    let amount: Decimal?
    let fee: Decimal?
    let preimage: String?
    let nodeId: String?
    let memo: String?
    
    init(payment: LightningPayment, userData: TxUserData) {
        let type: TxType = payment.type == .sent ? .sent(coin: .lightningBitcoin()) : .received(coin: .lightningBitcoin())
        
        switch payment.type {
        case .sent:
            self.sender = payment.nodeId
            self.receiver = nil
        case .received:
            self.sender = nil
            self.receiver = payment.nodeId
        }
        
        self.amount = Decimal(payment.amount)
        
        if let paymentFee = payment.fee {
            self.fee = Decimal(paymentFee)/1000/100_000_000
        } else {
            self.fee = nil
        }
        
        self.preimage = payment.preimage
        self.nodeId = payment.nodeId
        self.memo = payment.memo
                
        super.init(source: .lightning, type: type, id: payment.paymentId, timestamp: payment.timestamp, userData: userData)
    }
}

extension TransactionRecord {
    static var mockedLightning: TransactionRecord {
        _ = Bolt11Invoice.fromStr(s: "lntb150u1pjpm2rwpp5qtqkpsfupwnl5cm0jvd7v8asa3qd5y8kc2l2e3ua6v5dlszkzgyqdqqcqzpgxqyz5vqsp5kspjm0vlt6xhp5q6e78cp66e2fdx0lzg57ktf6kf30423qagstcq9qyyssq4l53zjvsqyc76ps7drxe2xjes2uvphh4ujr8dxpggx0sxcxtaa8q8f26k786gwrnususx5kcufr5gv5ktvj9d4vu9v8a2jehjhkv90spd6j4r3").getValue()!

        let payment = LightningPayment(
            nodeId: "hdyvu5uumvyt7j5twkpp55eham28a4cnwz3epal2geeceskmjs6pxp",
            paymentId: "hdyvu5uumvyt7j5twkpp55eham28a4cnwz3epal2geeceskmjs6pxp",
            amount: 100000,
            preimage: "lntb255m1p3l3qgadqqnp4qffgdax9g9ux3496d809u6le05nffsccvyuhdyvu5uumvyt7j5twkpp55eham28a4cnwz3epal2geeceskmjs6pxph987shgj3ydnv0nnqvssp5u8meh0nx9jaz68n97h3c22vxvmla2yynjgtcccpu5f4pjt7u7eps9qyysgqcqpcxqzlgsjl4nkpvgu4x54unwafr3s0h2mjtakw9cdklsa28qqdhmsxuqphhytyxlzwfx08nuwez5qvrvcfvkdgwdurtn67cr4l9wkdd6yu8rqgp88xwlu",
            type: .sent,
            timestamp: Int(Date().timeIntervalSince1970),
            fee: 1000,
            memo: String()
        )
        return LNTransactionRecord(payment: payment, userData: TxUserData(price: 1000))
    }
}

