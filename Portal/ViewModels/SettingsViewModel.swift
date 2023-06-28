//
//  SettingsViewModel.swift
//  Portal
//
//  Created by farid on 30.05.2023.
//

import Foundation
import Factory

class SettingsViewViewModel: ObservableObject {
    private var marketData: IMarketDataRepository = Container.marketData()
    
    @Injected(Container.settings) private var settings
    
    @Published var portfolioCurrencyIndex: Int = 0 {
        didSet {
            //settings.portfolioCurrency = portfolioCurrencies[portfolioCurrencyIndex]
        }
    }
    
    @Published var selectedCoins: [Coin] = [] {
        didSet {
            let selected = selectedCoins.map{ $0.code }
            guard settings.userCoins != selected else { return }
            settings.userCoins = selectedCoins.map{ $0.code }
            //accountManager.addCoin(coin: "coin.code")
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

    var fiatCurrencies: [FiatCurrency] {
        marketData.fiatCurrencies
    }
}
