//
//  StringFormatter.swift
//  BDKDemoApp
//
//  Created by farid on 23/8/22.
//

import Foundation

struct StringFormatter {
    static func localizedValueString(value: Decimal, symbol: String? = "$") -> String {
        let formatter = NumberFormatter()
        formatter.currencySymbol = symbol
        formatter.groupingSize = 3
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2 //value < 1 ? 2 : 0
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: value as NSDecimalNumber) ?? "#"
    }
    
    static func localizedValueString(value: Double, symbol: String? = "$") -> String {
        let formatter = NumberFormatter()
        formatter.currencySymbol = symbol
        formatter.groupingSize = 3
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2 //value < 1 ? 2 : 0
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "#"
    }
}
