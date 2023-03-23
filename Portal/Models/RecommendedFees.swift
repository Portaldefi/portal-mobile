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
    
    enum Keys: String, CodingKey {
        case high_fee_per_kb, medium_fee_per_kb, low_fee_per_kb
    }
    
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        
        let fastestFeeDecimal = try container.decode(Decimal.self, forKey: .high_fee_per_kb)/1000
        fastestFee = Decimal((fastestFeeDecimal as NSDecimalNumber).intValue)
        let halfHourFeeDecimal = try container.decode(Decimal.self, forKey: .medium_fee_per_kb)/1000
        halfHourFee = Decimal((halfHourFeeDecimal as NSDecimalNumber).intValue)
        let hourFeeDecimal = try container.decode(Decimal.self, forKey: .low_fee_per_kb)/1000
        hourFee = Decimal((hourFeeDecimal as NSDecimalNumber).intValue)
    }
    
    init(fastestFee: Decimal, halfHourFee: Decimal, hourFee: Decimal) {
        self.fastestFee = fastestFee
        self.halfHourFee = halfHourFee
        self.hourFee = hourFee
    }
}
