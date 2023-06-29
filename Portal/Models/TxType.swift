//
//  TxType.swift
//  Portal
//
//  Created by farid on 29.06.2023.
//

import Foundation

enum TxType: Equatable {
    case unknown, sent, received, swapped(for: Coin)
    
    var description: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .sent:
            return "Sent"
        case .received:
            return "Received"
        case .swapped(for: let coin):
            return "Swapped for \(coin.code)"
        }
    }
    
    static func typeFor(filter: TxTypeFilterOption) -> TxType {
        switch filter {
        case .none:
            return .unknown
        case .received:
            return .received
        case .send:
            return .sent
        case .swapped:
            return .swapped(for: .bitcoin())
        }
    }
}
