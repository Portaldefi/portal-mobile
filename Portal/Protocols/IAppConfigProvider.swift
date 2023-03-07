//
//  IAppConfigProvider.swift
//  Portal
//
//  Created by Farid on 15.07.2021.
//

import Foundation

protocol IAppConfigProvider {
    var companyWebPageLink: String { get }
    var appWebPageLink: String { get }
    var appGitHubLink: String { get }
    var reportEmail: String { get }
    var pricesUpdateInterval: Int { get }
    var fiatCurrenciesUpdateInterval: Int { get }
    var keychainStorageID: String { get }
    var mixpanelToken: String { get }
    var infuraCredentials: (id: String, secret: String?) { get }
    var etherscanKey: String { get }
    var fixerApiKey: String { get }
    var coinPaprikaApiKey: String { get }
    var btcCoreRpcUrl: String { get }
    var currencyCodes: [String] { get }
    var testMode: Bool { get }
    var feeRateAdjustedForCurrencyCodes: [String] { get }
    var rafaToken: String { get }
    var rafaUser: String { get }
    var rafaPass: String { get }
    var rafaSocketUrl: String { get }
    var forexUrl: String { get }
}
