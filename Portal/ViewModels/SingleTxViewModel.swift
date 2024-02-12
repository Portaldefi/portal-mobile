//
//  SingleTxViewModel.swift
// Portal
//
//  Created by farid on 11/3/22.
//

import Foundation
import Combine
import BitcoinDevKit
import Factory

class SingleTxViewModel: ObservableObject {
    let transaction: TransactionRecord
    
    var coin: Coin? {
        switch transaction.type {
        case .unknown:
            return nil
        case .sent(let coin), .received(let coin):
            return coin
        case .swap(let base, _):
            return base
        }
    }
    
    @Published private(set) var notes: String?
    @Published private(set) var labels: [TxLabel]
    
    @Injected(Container.settings) private var settings

    var fiatCurrency: FiatCurrency {
        settings.fiatCurrency.value
    }
    
    var amount: String {
        let txAmount: Decimal?
        
        switch transaction {
        case let record as BTCTransactionRecord:
            switch transaction.type {
            case .sent:
                if let amount = record.amount, let fee = record.fee {
                    txAmount = amount - (fee*100_000_000)
                } else {
                    txAmount = record.amount
                }
            default:
                txAmount = record.amount
            }
        case let record as EvmTransactionRecord:
            txAmount = record.amount
        case let record as LNTransactionRecord:
            txAmount = record.amount
        case let record as SwapTransactionRecord:
            txAmount = record.baseQuantity
        default:
            txAmount = nil
        }
        
        guard let amount = txAmount else { return "0" }
        
        switch transaction.type {
        case .sent(let coin), .received(let coin):
            switch coin.type {
            case .bitcoin, .lightningBitcoin:
                return (amount.double/100_000_000).toString(decimal: 8)
            case .ethereum, .erc20:
                return amount.double.toString(decimal: 8)
            }
        case .swap(_, let quote):
            switch quote.type {
            case .bitcoin, .lightningBitcoin:
                return (amount.double).toString(decimal: 8)
            case .ethereum, .erc20:
                return amount.double.toString(decimal: 8)
            }
        case .unknown:
            return String()
        }
    }
    
    var value: String {
        let txAmount: Decimal?
        
        switch transaction {
        case let record as BTCTransactionRecord:
            txAmount = record.amount
        case let record as EvmTransactionRecord:
            txAmount = record.amount
        case let record as LNTransactionRecord:
            txAmount = record.amount
        case let record as SwapTransactionRecord:
            txAmount = record.quoteQuantity
        default:
            txAmount = nil
        }
        
        guard let amount = txAmount else { return "0" }
        
        switch transaction.type {
        case .sent(let coin), .received(let coin):
            switch coin.type {
            case .bitcoin, .lightningBitcoin:
                return (amount/100_000_000 * transaction.price * fiatCurrency.rate).double.formattedString(.fiat(fiatCurrency))
            case .ethereum, .erc20:
                return (amount * transaction.price * fiatCurrency.rate).double.formattedString(.fiat(fiatCurrency))
            }
        case .swap:
            return amount.double.toString(decimal: 8)
        case .unknown:
            return String()
        }
    }
        
    init(transaction: TransactionRecord) {
        self.transaction = transaction
        self.notes = transaction.notes
        self.labels = transaction.labels
    }
}
