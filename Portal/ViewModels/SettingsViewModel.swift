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
