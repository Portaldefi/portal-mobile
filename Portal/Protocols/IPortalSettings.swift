//
//  IPortalSettings.swift
//  Portal
//
//  Created by farid on 19.07.2023.
//

import Foundation
import Combine

protocol IPortalSettings {
    var fiatCurrency: CurrentValueSubject<FiatCurrency, Never> { get }
    var userCoins: CurrentValueSubject<[String], Never> { get }
    var portfolioCurrency: CurrentValueSubject<Coin, Never> { get }
    var pincodeEnabled: CurrentValueSubject<Bool, Never> { get }
    var biometricsEnabled: CurrentValueSubject<Bool, Never> { get }
    
    func updateFiatCurrency(_ currency: FiatCurrency)
    func updatePortfolioCurrency(_ coin: Coin)
    func updateUserCoins(_ codes: [String])
    func updatePinCodeSetting(enabled: Bool)
    func updateBiometricsSetting(enabled: Bool)
}
