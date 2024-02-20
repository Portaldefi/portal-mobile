//
//  MockedPortalSettings.swift
//  Portal
//
//  Created by farid on 19.07.2023.
//

import Foundation
import Combine

struct MockedPortalSettings: IPortalSettings {
    private(set) var fiatCurrency: CurrentValueSubject<FiatCurrency, Never> = .init(FiatCurrency(code: "USD"))
    private(set) var userCoins: CurrentValueSubject<[String], Never> = .init([String]())
    private(set) var portfolioCurrency: CurrentValueSubject<Coin, Never> = .init(.bitcoin())
    private(set) var pincodeEnabled: CurrentValueSubject<Bool, Never> = .init(false)
    private(set) var biometricsEnabled: CurrentValueSubject<Bool, Never> = .init(false)
    private(set) var notificationsEnabled: CurrentValueSubject<Bool, Never> = .init(false)
    
    func updateFiatCurrency(_ currency: FiatCurrency) {
        fiatCurrency.send(currency)
    }
    
    func updatePortfolioCurrency(_ coin: Coin) {
        portfolioCurrency.send(coin)
    }
    
    func updateUserCoins(_ codes: [String]) {
        userCoins.send(codes)
    }
    
    func updatePinCodeSetting(enabled: Bool) {
        pincodeEnabled.send(enabled)
    }
    
    func updateBiometricsSetting(enabled: Bool) {
        biometricsEnabled.send(enabled)
    }
    
    func updateNotificationsSetting(enabled: Bool) {
        notificationsEnabled.send(enabled)
    }
}
