//
//  CurrencyTickerModel.swift
//  Portal
//
//  Created by farid on 3/7/23.
//

import Foundation

struct CurrencyTickerModel: Decodable {
    var ticker: String
    var bid: String
    var ask: String
    var open: String
    var low: String
    var high: String
    var changes: Decimal
    var date: String
}
