//
//  SettingsViewModel.swift
//  Portal
//
//  Created by farid on 30.05.2023.
//

import Foundation
import Factory

class SettingsViewViewModel: ObservableObject {
    @Injected(Container.coinManager) private var coinManager
    @Injected(Container.marketData) private var marketData
    @Injected(Container.settings) private var settings
    @Injected(Container.accountManager) private var accountManager
    
    @Published var portfolioCurrencyIndex: Int = 0 {
        didSet {
            settings.portfolioCurrency = portfolioCurrencies[portfolioCurrencyIndex]
        }
    }
    
    @Published var selectedCoins: [Coin] = [] {
        didSet {
            let selected = selectedCoins.map{ $0.code }
            guard settings.userCoins != selected else { return }
            settings.userCoins = selectedCoins.map{ $0.code }
            accountManager.addCoin(coin: "coin.code")
        }
    }
        
    var fiatCurrency: FiatCurrency {
        get {
            settings.fiatCurrency
        }
        set {
            settings.fiatCurrency = newValue
        }
    }
    
    init() {
        let currency = settings.portfolioCurrency
        portfolioCurrencyIndex = portfolioCurrencies.firstIndex(of: currency) ?? 0
        
        selectedCoins = settings.userCoins.compactMap { code in
            coins.first(where: { $0.code == code})
        } 
    }

    var fiatCurrencies: [FiatCurrency] {
        marketData.fiatCurrencies
    }
    
    var portfolioCurrencies: [Coin] {
        [.bitcoin(), .ethereum()]
    }
    
    var coins: [Coin] {
        coinManager.avaliableCoins
    }
}
