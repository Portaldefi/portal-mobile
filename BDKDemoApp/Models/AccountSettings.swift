//
//  AccountSettings.swift
//  BDKDemoApp
//
//  Created by farid on 9/1/22.
//

import Foundation
import Combine

class AccountSettings: ObservableObject {
    private var currencies: [Currency] = [
        Currency.sat, Currency.btc
    ]
    
    @Published var currency: Currency = .btc
    
    func nextCurrency() {
        guard let nextCurrency = currencies.first(where: { $0 != currency }) else { return }
        currency = nextCurrency
        print("New currency: \(currency.name)")
    }
}
