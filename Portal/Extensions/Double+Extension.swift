//
//  Double+Extension.swift
//  Portal
//
//  Created by farid on 23/8/22.
//

import Foundation

extension Double {
    func dollarFormatted() -> String {
        StringFormatter.localizedValueString(value: self, symbol: "$")
    }
    func btcFormatted() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        return String(formatter.string(from: number) ?? "")
    }
    func ethFormatted() -> String {
        roundToDecimal(6).toString() + " ETH"
    }
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
    func toString(decimal: Int = 12) -> String {
        let value = decimal < 0 ? 0 : decimal
        var string = String(format: "%.\(value)f", self)
        
        while string.last == "0" || string.last == "." {
            if string.last == "." { string = String(string.dropLast()); break }
            string = String(string.dropLast())
        }
        if string == "0" {
            string = "0.0"
        }
        return string
    }
    
    func fiatFormatted(_ symbol: String? = "$") -> String {
        let formatter = NumberFormatter()
        formatter.currencySymbol = symbol
        formatter.groupingSize = 3
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2 //self < 1 ? 2 : 0
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? "#"
    }
    
    func precisionString() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 18
        return String(formatter.string(from: number) ?? "")
    }
    
    func formattedString(_ currency: AccountCurrency, decimals: Int = 5) -> String {
        let formatter = NumberFormatter()
        
        switch currency {
        case .fiat(let fiatCurrency):
            formatter.currencySymbol = fiatCurrency.symbol
            formatter.groupingSize = 3
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            formatter.minimumIntegerDigits = 1
            return formatter.string(from: NSNumber(value: self)) ?? "-"
        case .coin:
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = decimals
            formatter.minimumFractionDigits = 0
            formatter.minimumIntegerDigits = 1
            return (formatter.string(from: NSNumber(value: self)) ?? "-")
        }
    }
    
    func usdFormatted() -> String {
        let formatter = NumberFormatter()
        formatter.groupingSize = 3
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? "-"
    }
}
