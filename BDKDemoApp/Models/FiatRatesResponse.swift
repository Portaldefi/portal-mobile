//
//  FiatRatesResponse.swift
//  Portal
//
//  Created by farid on 1/20/22.
//

import Foundation

typealias Rates = [String : Double]

struct FiatRatesResponse: Codable {
    let success: Bool
    let rates: Rates?
}
