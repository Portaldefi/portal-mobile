//
//  RecommendedFees.swift
//  Portal
//
//  Created by farid on 10/4/22.
//

import Foundation

struct RecomendedFees: Codable {
    let fastestFee: Int
    let halfHourFee: Int
    let hourFee: Int
    
    func fee(_ state: TxFees) -> Int {
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
