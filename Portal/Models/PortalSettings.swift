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
            updateFiatCurrencySetting()
        }
    }
    
    @Published var userCoins = [String]() {
        didSet {
            updateUserCoinsSetting()
        }
    }
    
    @Published var portfolioCurrency = Coin.bitcoin() {
        didSet {
            updatePortfolioCurrencySetting()
        }
    }
    
    @Published var pincodeEnabled = false {
        didSet {
            updatePinCodeSetting()
        }
    }
    
    @Published var biometricsEnabled = false {
        didSet {
            updateBiometricsSetting()
        }
    }
    
    @Preference(\.fiatCurrencyData) private var fiatCurrencyPreference
    @Preference(\.portfolioCurrencyData) private var portfolioCurrencyPreference
    @Preference(\.userCoins) private var userCoinsPreference
    @Preference(\.pincodeEnabled) private var pincodeEnabledPreference
    @Preference(\.biometricsEnabled) private var biometricsEnabledPreference
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        guard
            let data = fiatCurrencyPreference.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(FiatCurrency.self, from: data)
        else { return }
        
        fiatCurrency = decoded
        
        switch portfolioCurrencyPreference {
        case "ETH":
            portfolioCurrency = .ethereum()
        default:
            break
        }
        
        userCoins = userCoinsPreference
        pincodeEnabled = pincodeEnabledPreference
        biometricsEnabled = biometricsEnabledPreference
        
        Preferences.standard
            .preferencesChangedSubject
            .filter { changedKeyPath in
                changedKeyPath == \Preferences.biometricsEnabled
            }.sink { [weak self] _ in
                guard let self = self else { return }
                self.biometricsEnabled = self.biometricsEnabledPreference
            }
            .store(in: &subscriptions)
        
        Preferences.standard
            .preferencesChangedSubject
            .filter { changedKeyPath in
                changedKeyPath == \Preferences.pincodeEnabled
            }.sink { [weak self] _ in
                guard let self = self else { return }
                self.pincodeEnabled = self.pincodeEnabledPreference
            }
            .store(in: &subscriptions)
    }
    
    private func updateFiatCurrencySetting() {
        guard
            let encodedCurrencyData = try? JSONEncoder().encode(fiatCurrency),
            let encodedString = String(data: encodedCurrencyData, encoding: .utf8),
            fiatCurrencyPreference != encodedString
        else { return }
        
        self.fiatCurrencyPreference = encodedString
    }
    
    private func updatePortfolioCurrencySetting() {
        portfolioCurrencyPreference = portfolioCurrency.code
    }
    
    private func updateUserCoinsSetting() {
        userCoinsPreference = userCoins
    }
    
    private func updatePinCodeSetting() {
        guard pincodeEnabledPreference != pincodeEnabled else { return }
        pincodeEnabledPreference = pincodeEnabled
    }
    
    private func updateBiometricsSetting() {
        guard biometricsEnabledPreference != biometricsEnabled else { return }
        biometricsEnabledPreference = biometricsEnabled
    }
}
