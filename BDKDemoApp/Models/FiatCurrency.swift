//
//  FiatCurrency.swift
//  BDKDemoApp
//
//  Created by farid on 23/8/22.
//

import Foundation

struct FiatCurrency: Codable {
    let code: String
    let name: String
    let rate: Double
    
    var symbol: String {
        get {
            getSymbolForCurrencyCode(code: code) ?? "-"
        }
    }
    
    init(code: String, name: String, rate: Double = 1.0) {
        self.code = code
        self.name = name
        self.rate = rate
    }
    
    private func getSymbolForCurrencyCode(code: String) -> String? {
        var candidates: [String] = []
        let locales: [String] = NSLocale.availableLocaleIdentifiers
        for localeID in locales {
            guard let symbol = findMatchingSymbol(localeID: localeID, currencyCode: code) else {
                continue
            }
            if symbol.count == 1 {
                return symbol
            }
            candidates.append(symbol)
        }
        let sorted = sortAscByLength(list: candidates)
        if sorted.count < 1 {
            return nil
        }
        return sorted[0]
    }
    
    private func findMatchingSymbol(localeID: String, currencyCode: String) -> String? {
        let locale = Locale(identifier: localeID as String)
        guard let code = locale.currencyCode else {
            return nil
        }
        if code != currencyCode {
            return nil
        }
        guard let symbol = locale.currencySymbol else {
            return nil
        }
        return symbol
    }
    
    private func sortAscByLength(list: [String]) -> [String] {
        return list.sorted(by: { $0.count < $1.count })
    }
}
