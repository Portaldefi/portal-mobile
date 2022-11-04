//
//  FiatSymbols.swift
//  Portal
//
//  Created by farid on 1/20/22.
//

import Foundation

struct FiatSymbols: Codable {
    let success: Bool
    let symbols: [String: String]?
}
