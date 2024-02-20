//
//  PortalSettings.swift
//  Portal
//
//  Created by farid on 30.05.2023.
//

import Foundation
import Combine

class PortalSettings: IPortalSettings {
    private(set) var fiatCurrency: CurrentValueSubject<FiatCurrency, Never> = .init(FiatCurrency(code: "USD"))
    private(set) var userCoins: CurrentValueSubject<[String], Never> = .init([String]())
    private(set) var portfolioCurrency: CurrentValueSubject<Coin, Never> = .init(.bitcoin())
    private(set) var pincodeEnabled: CurrentValueSubject<Bool, Never> = .init(false)
    private(set) var biometricsEnabled: CurrentValueSubject<Bool, Never> = .init(false)
    private(set) var notificationsEnabled: CurrentValueSubject<Bool, Never> = .init(false)
        
    @Preference(\.fiatCurrencyData) private var fiatCurrencyPreference
    @Preference(\.portfolioCurrencyData) private var portfolioCurrencyPreference
    @Preference(\.userCoins) private var userCoinsPreference
    @Preference(\.pincodeEnabled) private var pincodeEnabledPreference
    @Preference(\.biometricsEnabled) private var biometricsEnabledPreference
    @Preference(\.notificationsEnabled) private var notificationsEnabledPreference
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        if let data = fiatCurrencyPreference.data(using: .utf8), let decoded = try? JSONDecoder().decode(FiatCurrency.self, from: data) {
            fiatCurrency.send(decoded)
        }
        
        switch portfolioCurrencyPreference {
        case "ETH":
            portfolioCurrency.send(.ethereum())
        default:
            break
        }
        
        userCoins.send(userCoinsPreference)
        pincodeEnabled.send(pincodeEnabledPreference)
        biometricsEnabled.send(biometricsEnabledPreference)
        notificationsEnabled.send(notificationsEnabledPreference)
        
        Preferences.standard.preferencesChangedSubject
            .sink {  [weak self] keyPath in
                guard let self = self else { return }
                
                switch keyPath {
                case \Preferences.pincodeEnabled:
                    self.biometricsEnabled.send(self.biometricsEnabledPreference)
                case \Preferences.pincodeEnabled:
                    self.pincodeEnabled.send(self.pincodeEnabledPreference)
                case \Preferences.notificationsEnabled:
                    self.notificationsEnabled.send(self.notificationsEnabledPreference)
                default:
                    break
                }
            }
            .store(in: &subscriptions)
    }
    
    func updateFiatCurrency(_ currency: FiatCurrency) {
        guard
            let encodedCurrencyData = try? JSONEncoder().encode(currency),
            let encodedString = String(data: encodedCurrencyData, encoding: .utf8),
            fiatCurrencyPreference != encodedString
        else { return }
        
        self.fiatCurrencyPreference = encodedString
        self.fiatCurrency.send(currency)
    }
    
    func updatePortfolioCurrency(_ coin: Coin) {
        guard portfolioCurrencyPreference != coin.code else { return }
        portfolioCurrencyPreference = coin.code
        portfolioCurrency.send(coin)
    }
    
    func updateUserCoins(_ codes: [String]) {
        guard userCoinsPreference != codes else { return }
        userCoinsPreference = codes
        userCoins.send(codes)
    }
    
    func updatePinCodeSetting(enabled: Bool) {
        guard pincodeEnabledPreference != enabled else { return }
        pincodeEnabledPreference = enabled
        pincodeEnabled.send(enabled)
    }
    
    func updateBiometricsSetting(enabled: Bool) {
        guard biometricsEnabledPreference != enabled else { return }
        biometricsEnabledPreference = enabled
        biometricsEnabled.send(enabled)
    }
    
    func updateNotificationsSetting(enabled: Bool) {
        guard notificationsEnabledPreference != enabled else { return }
        notificationsEnabledPreference = enabled
        notificationsEnabled.send(enabled)
    }
}
