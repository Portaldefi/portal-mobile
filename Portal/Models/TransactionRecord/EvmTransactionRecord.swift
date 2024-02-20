//
//  EvmTransactionRecord.swift
//  Portal
//
//  Created by farid on 12.01.2024.
//

import Foundation
import EvmKit

class EvmTransactionRecord: TransactionRecord {
    let coin: Coin
    let blockHeight: Int?
    let sender: String?
    let receiver: String?
    let amount: Decimal?
    let fee: Decimal?
    
    init(coin: Coin, transaction: EvmKit.Transaction, type: TxType, amount: Decimal?, sender: String?, receiver: String?, userData: TxUserData) {
        self.coin = coin
        
        self.amount = amount
        self.receiver = receiver
        self.sender = sender
        self.blockHeight = transaction.blockNumber
        
        if let feeAmount = transaction.gasUsed ?? transaction.gasLimit, let gasPrice = transaction.gasPrice {
            let feeDecimal = Decimal(sign: .plus, exponent: -coin.decimal, significand: Decimal(feeAmount) * Decimal(gasPrice))
            fee = feeDecimal
        } else {
            fee = nil
        }
        
        super.init(source: .ethereum, type: type, id: transaction.hash.hs.hexString, timestamp: transaction.timestamp, userData: userData)
    }
}
