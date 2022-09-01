//
//  Currency.swift
//  BDKDemoApp
//
//  Created by farid on 23/8/22.
//

import Foundation

enum Currency: Equatable {
    static func == (lhs: Currency, rhs: Currency) -> Bool {
        lhs.symbol == rhs.symbol
    }
    
    case fiat(FiatCurrency)
    case sat
    case btc
    case eth
    
    var symbol: String {
        switch self {
        case .fiat(let currency):
            return currency.symbol
        case .sat:
            return "sats"
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
        case .sat:
            return "sats"
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
        case .sat:
            return "Satoshies"
        case .eth:
            return "Ethereum"
        }
    }
}
