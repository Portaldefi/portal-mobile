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
    let tx: TransactionRecord
    
    var coin: Coin? {
        switch tx.type {
        case .unknown:
            return nil
        case .sent(let coin), .received(let coin):
            return coin
        case .swap(let base, let quote):
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
        guard let amount = tx.amount else { return "0" }
        switch tx.type {
        case .sent(let coin), .received(let coin), .swap(let coin, _):
            switch coin.type {
            case .bitcoin:
                return (amount.double/100_000_000).toString(decimal: 8)
            case .ethereum:
                return amount.double.toString(decimal: 8)
            case .erc20:
                return amount.double.toString(decimal: 8)
            case .lightningBitcoin:
                return (amount.double/100_000_000).toString(decimal: 8)
            }
        case .unknown:
            return String()
        }
    }
    
    var value: String {
        guard let amount = tx.amount else { return "0" }
        
        switch tx.type {
        case .sent(let coin), .received(let coin), .swap(let coin, _):
            switch coin.type {
            case .bitcoin, .lightningBitcoin:
                return (amount/100_000_000 * tx.userData.price * fiatCurrency.rate).double.formattedString(.fiat(fiatCurrency))
            case .ethereum:
                return (amount * tx.userData.price * fiatCurrency.rate).double.formattedString(.fiat(fiatCurrency))
            case .erc20:
                return (amount * tx.userData.price * fiatCurrency.rate).double.formattedString(.fiat(fiatCurrency))
            }
        case .unknown:
            return String()
        }
    }
        
    init(tx: TransactionRecord) {
        self.tx = tx
        self.notes = tx.notes
        self.labels = tx.labels
    }
}
