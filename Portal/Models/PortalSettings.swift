//
//  PortalSettings.swift
//  Portal
//
//  Created by farid on 30.05.2023.
//

import Foundation
import Combine

class PortalSettings: ObservableObject {
    @Published var fiatCurrency = FiatCurrency(code: "USD") {
        didSet {
            updateFiatCurrencyData()
        }
    }
    
    @Published var userCoins = [String]() {
        didSet {
            updateUserCoins()
        }
    }
    
    @Published var portfolioCurrency = Coin.bitcoin() {
        didSet {
            updatePortfolioCurrency()
        }
    }
    
    @Preference(\.fiatCurrencyData) private var fiatCurrencyData
    @Preference(\.portfolioCurrencyData) private var portfolioCurrencyData
    @Preference(\.userCoins) private var userCoinsData
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        guard
            let data = fiatCurrencyData.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(FiatCurrency.self, from: data)
        else { return }
        
        fiatCurrency = decoded
        
        switch portfolioCurrencyData {
        case "ETH":
            portfolioCurrency = .ethereum()
        default:
            break
        }
        
        userCoins = userCoinsData
    }
    
    private func updateFiatCurrencyData() {
        guard
            let encodedCurrencyData = try? JSONEncoder().encode(fiatCurrency),
            let encodedString = String(data: encodedCurrencyData, encoding: .utf8),
            fiatCurrencyData != encodedString
        else { return }
        
        self.fiatCurrencyData = encodedString
    }
    
    private func updatePortfolioCurrency() {
        portfolioCurrencyData = portfolioCurrency.code
    }
    
    private func updateUserCoins() {
        userCoinsData = userCoins
    }
}
