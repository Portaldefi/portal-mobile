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
        case .sent:
            return "Sent"
        case .received:
            return "Received"
        case .swap(let base, let quote):
            return "\(base.code) to \(quote.code)"
        }
    }
}
