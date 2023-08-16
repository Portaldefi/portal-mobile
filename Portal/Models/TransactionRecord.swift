import Foundation
import Lightning
import BitcoinDevKit
import EvmKit
import LightningDevKit

enum TxSource {
    case btcOnChain, ethOnChain, lightning
}

import Factory

struct TransactionRecord: Identifiable {
    let coin: Coin
    let id: String
    let type: TxType
    let timestamp: Int?
    let blockHeight: Int?
    let from: String?
    let to: String?
    let amount: Decimal?
    let fee: Decimal?
    let source: TxSource
    let preimage: String?
    let nodeId: String?
    let userData: TxUserData
        
    var confirmationTimeString: String? {
        guard let confirmationTime = self.timestamp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(confirmationTime)).formatted()
    }
    
    var notes: String?  {
        userData.notes
    }
    
    var labels: [TxLabel] {
        userData.labels
    }
    
    init(transaction: BitcoinDevKit.TransactionDetails, userData: TxUserData) {
        self.id = transaction.txid
        self.coin = .bitcoin()
        
        let sent = transaction.sent
        let received = transaction.received
        
        if sent > 0, received > 0 {
            self.type = sent > received ? .sent : .received
            
            switch type {
            case .sent:
                self.amount = Decimal(sent - received)
            case .received:
                self.amount = Decimal(received - sent)
            case .swapped, .unknown:
                fatalError("should not happen")
            }
        } else if sent == 0, received > 0 {
            self.type = .received
            self.amount = Decimal(transaction.received)
        } else if sent > 0, received == 0 {
            self.type = .sent
            self.amount = Decimal(transaction.sent)
        } else {
            self.type = .sent
            self.amount = 0
        }
        
        if let blockInfo = transaction.confirmationTime {
            self.timestamp = Int(blockInfo.timestamp)
            self.blockHeight = Int(blockInfo.height)
        } else {
            self.timestamp = nil
            self.blockHeight = nil
        }
        
        self.from = nil
        self.to = nil
        self.source = .btcOnChain
        
        if let fee = transaction.fee {
            self.fee = Decimal(fee)/100_000_000
        } else {
            self.fee = nil
        }
        preimage = nil
        nodeId = nil
        
        self.userData = userData
    }
    
    init(coin: Coin, transaction: EvmKit.Transaction, amount: Decimal?, type: TxType, userData: TxUserData) {
        self.id = transaction.hash.hs.hexString
        self.coin = coin
        self.type = type
        self.amount = amount
        self.to = transaction.to?.hex
        self.from = transaction.from?.hex
        self.timestamp = transaction.timestamp
        self.blockHeight = transaction.blockNumber
        self.source = .ethOnChain
                
        if let feeAmount = transaction.gasUsed ?? transaction.gasLimit, let gasPrice = transaction.gasPrice {
            let feeDecimal = Decimal(sign: .plus, exponent: -coin.decimal, significand: Decimal(feeAmount) * Decimal(gasPrice))
            fee = feeDecimal
        } else {
            fee = nil
        }
        
        preimage = nil
        nodeId = nil
        
        self.userData = userData
    }
    
    init(token: Erc20Token, transaction: EvmKit.Transaction, amount: Decimal?, type: TxType, from: String?, to: String?, userData: TxUserData) {
        self.id = transaction.hash.hs.hexString
        self.type = type
        self.coin = Coin(type: .erc20(address: token.contractAddress), code: token.code, name: token.name, decimal: token.decimal, iconUrl: token.name)
        self.amount = amount
        self.to = to ?? "-"
        self.from = from ?? "-"
        self.timestamp = transaction.timestamp
        self.blockHeight = transaction.blockNumber
        self.source = .ethOnChain
        
        
        if let feeAmount = transaction.gasUsed ?? transaction.gasLimit, let gasPrice = transaction.gasPrice {
            let feeDecimal = Decimal(sign: .plus, exponent: -token.decimal, significand: Decimal(feeAmount) * Decimal(gasPrice))
            fee = feeDecimal
        } else {
            fee = nil
        }
        
        preimage = nil
        nodeId = nil
        
        self.userData = userData
    }
        
    init(payment: LightningPayment, userData: TxUserData) {
        self.id = payment.paymentId
        self.coin = .bitcoin()
        self.type = payment.type == .sent ? .sent : .received
        self.source = .lightning
        self.timestamp = payment.timestamp
        
        switch payment.type {
        case .sent:
            self.from = payment.nodeId
            self.to = nil
        case .received:
            self.from = nil
            self.to = payment.nodeId
        }
        
        self.amount = Decimal(payment.amount)
        
        if let paymentFee = payment.fee {
            self.fee = Decimal(paymentFee)/1000/100_000_000
        } else {
            self.fee = nil
        }
        
        self.preimage = payment.preimage
        self.nodeId = payment.nodeId
        self.blockHeight = nil
        
        self.userData = userData
    }
}

extension TransactionRecord: Hashable {
    public static func ==(lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension TransactionRecord {
    static func mocked(confirmed: Bool) -> TransactionRecord {
        if confirmed {
            return TransactionRecord(transaction: TransactionDetails.mockedConfirmed, userData: TxUserData(price: 1000))
        } else {
            return TransactionRecord(transaction: TransactionDetails.unconfirmedSentTransaction(recipient: "recepient", amount: "100", id: "sakfudhiecsx,nsdweodjh@KRHuh"), userData: TxUserData(price: 1000))
        }
    }
    
    static var mockedLightning: TransactionRecord {
        _ = Invoice.fromStr(s: "lntb150u1pjpm2rwpp5qtqkpsfupwnl5cm0jvd7v8asa3qd5y8kc2l2e3ua6v5dlszkzgyqdqqcqzpgxqyz5vqsp5kspjm0vlt6xhp5q6e78cp66e2fdx0lzg57ktf6kf30423qagstcq9qyyssq4l53zjvsqyc76ps7drxe2xjes2uvphh4ujr8dxpggx0sxcxtaa8q8f26k786gwrnususx5kcufr5gv5ktvj9d4vu9v8a2jehjhkv90spd6j4r3").getValue()!

        let payment = LightningPayment(
            nodeId: "hdyvu5uumvyt7j5twkpp55eham28a4cnwz3epal2geeceskmjs6pxp",
            paymentId: "hdyvu5uumvyt7j5twkpp55eham28a4cnwz3epal2geeceskmjs6pxp",
            amount: 100000,
            preimage: "lntb255m1p3l3qgadqqnp4qffgdax9g9ux3496d809u6le05nffsccvyuhdyvu5uumvyt7j5twkpp55eham28a4cnwz3epal2geeceskmjs6pxph987shgj3ydnv0nnqvssp5u8meh0nx9jaz68n97h3c22vxvmla2yynjgtcccpu5f4pjt7u7eps9qyysgqcqpcxqzlgsjl4nkpvgu4x54unwafr3s0h2mjtakw9cdklsa28qqdhmsxuqphhytyxlzwfx08nuwez5qvrvcfvkdgwdurtn67cr4l9wkdd6yu8rqgp88xwlu",
            type: .sent,
            timestamp: Int(Date().timeIntervalSince1970),
            fee: 1000
        )
        return TransactionRecord(payment: payment, userData: TxUserData(price: 1000))
    }
}
