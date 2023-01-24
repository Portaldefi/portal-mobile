//
//  UInt64+Extension.swift
//  Portal
//
//  Created by farid on 23/8/22.
//

import Foundation

extension UInt64 {
    func formattedString(_ currency: AccountCurrency, decimals: Int = 0) -> String {
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
            formatter.numberStyle = .none
            formatter.maximumFractionDigits = decimals
            formatter.minimumFractionDigits = 0
            formatter.minimumIntegerDigits = 1
            return (formatter.string(from: NSNumber(value: self)) ?? "-")
        }
    }
    
    func localizedValueString(value: Double, symbol: String? = "$") -> String {
        let formatter = NumberFormatter()
        formatter.currencySymbol = symbol
        formatter.groupingSize = 3
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2 //value < 1 ? 2 : 0
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "#"
    }
    
    func totalValueString(currency: AccountCurrency) -> String {
        let double = Double(self)
        switch currency {
        case .fiat(let currency):
            return localizedValueString(value: double * currency.rate, symbol: currency.symbol)
        case .coin(let coin):
            switch coin.type {
            case .bitcoin, .lightningBitcoin:
                return double.btcFormatted()
            case .ethereum, .erc20:
                return double.ethFormatted()
            }
        }
    }
}
