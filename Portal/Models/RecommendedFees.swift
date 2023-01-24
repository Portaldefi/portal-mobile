//
//  RecommendedFees.swift
//  Portal
//
//  Created by farid on 10/4/22.
//

import Foundation

struct RecomendedFees: Codable {
    let fastestFee: Decimal
    let halfHourFee: Decimal
    let hourFee: Decimal
    
    func fee(_ state: TxFees) -> Decimal {
        switch state {
        case .normal:
            return halfHourFee
        case .fast:
            return fastestFee
        case .slow:
            return hourFee
        case .custom:
            fatalError("custom fees not implemented")
        }
    }
}
