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
            settings.updatePortfolioCurrency(portfolioCurrencies[portfolioCurrencyIndex])
        }
    }
    
    @Published private(set) var selectedCoins: [Coin] = []
        
    var fiatCurrency: FiatCurrency {
        get {
            settings.fiatCurrency.value
        }
        set {
            settings.updateFiatCurrency(newValue)
            objectWillChange.send()
        }
    }
    
    init() {
        let currency = settings.portfolioCurrency.value
        portfolioCurrencyIndex = portfolioCurrencies.firstIndex(of: currency) ?? 0
        
        selectedCoins = settings.userCoins.value.compactMap { code in
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
    
    func updateWallet() {
        let selected = selectedCoins.map{ $0.code }
        guard settings.userCoins.value != selected else { return }
        settings.updateUserCoins(selectedCoins.map{ $0.code })
        accountManager.addCoin(coin: "coin.code")
    }
    
    func updatedWallet(_ coin: Coin) {
        if selectedCoins.contains(coin) {
            selectedCoins.removeAll(where: { $0 == coin })
        } else {
            selectedCoins.append(coin)
        }
    }
}
