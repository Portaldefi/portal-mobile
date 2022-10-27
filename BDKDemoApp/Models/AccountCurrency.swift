//
//  AccountCurrency.swift
//  BDKDemoApp
//
//  Created by farid on 23/8/22.
//

import Foundation

enum AccountCurrency: Equatable {
    static func == (lhs: AccountCurrency, rhs: AccountCurrency) -> Bool {
        lhs.symbol == rhs.symbol
    }
    
    case fiat(FiatCurrency)
    case btc
    case eth
    
    var symbol: String {
        switch self {
        case .fiat(let currency):
            return currency.symbol
        case .btc:
            return "₿"
        case .eth:
            return "Ξ"
        }
    }
    
    var code: String {
        switch self {
        case .fiat(let currency):
            return currency.code
        case .btc:
            return "BTC"
        case .eth:
            return "ETH"
        }
    }
    
    var name: String {
        switch self {
        case .fiat(let currency):
            return currency.name
        case .btc:
            return "Bitcoin"
        case .eth:
            return "Ethereum"
        }
    }
}
