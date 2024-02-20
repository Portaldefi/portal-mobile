//
//  SettingsViewModel.swift
//  Portal
//
//  Created by farid on 30.05.2023.
//

import Foundation
import Factory
import Combine

class SettingsViewViewModel: ObservableObject {
    @Injected(Container.coinManager) private var coinManager
    @Injected(Container.notificationService) private var notificationService
    @Injected(Container.marketData) private var marketData
    @Injected(Container.settings) private var settings
    @Injected(Container.accountManager) private var accountManager
    
    var notificationsEnrolledPublisher: AnyPublisher<Bool, Never> {
        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .flatMap { _ in
                Future<Bool, Never> { [unowned self] promise in
                    Task { promise(.success(await isNotificationsEnrolled())) }
                }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    @Published var portfolioCurrencyIndex: Int = 0 {
        didSet {
            settings.updatePortfolioCurrency(portfolioCurrencies[portfolioCurrencyIndex])
        }
    }
    
    @Published private(set) var selectedCoins: [Coin] = []
    
    @Published var notificationsEnabled = false {
        didSet {
            guard notificationsEnabled != settings.notificationsEnabled.value else { return }
            
            if notificationsEnabled {
                notificationService.requestAuthorization { [unowned self] granted in
                    if granted {
                        settings.updateNotificationsSetting(enabled: granted)
                    } else {
                        notificationsEnabled = false
                    }
                }
            } else {
                guard settings.notificationsEnabled.value else { return }
                settings.updateNotificationsSetting(enabled: false)
            }
        }
    }
        
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
        notificationsEnabled = settings.notificationsEnabled.value
        
        selectedCoins = settings.userCoins.value.compactMap { code in
            coins.first(where: { $0.code == code})
        } 
    }

    var fiatCurrencies: [FiatCurrency] {
        marketData.fiatCurrencies
    }
    
    var portfolioCurrencies: [Coin] {
        [.bitcoin()]
    }
    
    var coins: [Coin] {
        coinManager.avaliableCoins
    }
    
    func isNotificationsEnrolled() async -> Bool {
        await self.notificationService.isNotificationsEnrolled()
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
