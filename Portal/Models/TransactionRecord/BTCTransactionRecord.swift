//
//  BTCTransactionRecord.swift
//  Portal
//
//  Created by farid on 12.01.2024.
//

import Foundation
import BitcoinDevKit

class BTCTransactionRecord: TransactionRecord {
    let coin: Coin = .bitcoin()
    
    let blockHeight: Int?
    let sender: String?
    let receiver: String?
    let amount: Decimal?
    let fee: Decimal?
    
    init(transaction: BitcoinDevKit.TransactionDetails, userData: TxUserData) {
        let sent = transaction.sent
        let received = transaction.received
        let type: TxType
        let timestamp: Int?
        
        if sent > 0, received > 0 {
            type = sent > received ? .sent(coin: .bitcoin()) : .received(coin: .bitcoin())
            
            switch type {
            case .sent:
                amount = Decimal(sent - received)
            case .received:
                amount = Decimal(received - sent)
            default:
                fatalError("should not happen")
            }
        } else if sent == 0, received > 0 {
            type = .received(coin: .bitcoin())
            amount = Decimal(transaction.received)
        } else if sent > 0, received == 0 {
            type = .sent(coin: .bitcoin())
            amount = Decimal(transaction.sent)
        } else {
            type = .sent(coin: .bitcoin())
            amount = 0
        }
        
        if let blockInfo = transaction.confirmationTime {
            timestamp = Int(blockInfo.timestamp)
            blockHeight = Int(blockInfo.height)
        } else {
            timestamp = nil
            blockHeight = nil
        }
        
        if let tx = transaction.transaction {
            var recipients = String()
            
            for input in tx.input() {
                guard let address = try? Address.fromScript(script: input.scriptSig, network: .regtest) else { continue }
                print("Input \(address.asString())")
            }
            
            for output in tx.output() {
                guard let address = try? Address.fromScript(script: output.scriptPubkey, network: .regtest) else { continue }
                recipients.append(recipients.isEmpty ? "\(address.asString())" : "\n\(address.asString())")
            }
            
            sender = nil
            receiver = recipients
        } else {
            sender = nil
            receiver = nil
        }
                
        if let fee = transaction.fee {
            self.fee = Decimal(fee)/100_000_000
        } else {
            self.fee = nil
        }
                
        let source: TxSource = .bitcoin
        
        super.init(source: source, type: type, id: transaction.txid, timestamp: timestamp, userData: userData)
    }
}

extension TransactionRecord {
    static func mocked(confirmed: Bool) -> TransactionRecord {
        if confirmed {
            return BTCTransactionRecord(transaction: TransactionDetails.mockedConfirmed, userData: TxUserData(price: 1000))
        } else {
            return BTCTransactionRecord(transaction: TransactionDetails.unconfirmedSentTransaction(recipient: "recepient", amount: "100", id: "sakfudhiecsx,nsdweodjh@KRHuh"), userData: TxUserData(price: 1000))
        }
    }
}
