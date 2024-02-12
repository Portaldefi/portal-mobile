//
//  TxType.swift
//  Portal
//
//  Created by farid on 29.06.2023.
//

import Foundation

enum TxType: Equatable {
    case unknown, sent(coin: Coin), received(coin: Coin), swap(base: Coin, quote: Coin)
    
    var description: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .sent(let coin):
            return "Sent \(coin.code)"
        case .received(let coin):
            return "Received \(coin.code)"
        case .swap(let base, let quote):
            return "\(base.code) to \(quote.code)"
        }
    }
}
