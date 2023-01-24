//
//  AccountCurrency.swift
//  Portal
//
//  Created by farid on 23/8/22.
//

import Foundation

enum AccountCurrency: Equatable {
    static func == (lhs: AccountCurrency, rhs: AccountCurrency) -> Bool {
        lhs.symbol == rhs.symbol
    }
    
    case fiat(FiatCurrency)
    case coin(Coin)
    
    var symbol: String {
        switch self {
        case .fiat(let currency):
            return currency.symbol
        case .coin(let coin):
            switch coin.type {
            case .bitcoin, .lightningBitcoin:
                return "₿"
            case .ethereum, .erc20:
                return "Ξ"
            }
        }
    }
    
    var code: String {
        switch self {
        case .fiat(let currency):
            return currency.code
        case .coin(let coin):
            return coin.code
        }
    }
    
    var name: String {
        switch self {
        case .fiat(let currency):
            return currency.name
        case .coin(let coin):
            return coin.name
        }
    }
}
