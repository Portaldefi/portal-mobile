//
//  AppConfigProvider.swift
//  Portal
//
//  Created by Farid on 15.07.2021.
//

import Foundation

class AppConfigProvider: IAppConfigProvider {
    let companyWebPageLink = "https://getportal.co"
    let appWebPageLink = "https://getportal.co"
    let appGitHubLink = ""
    let reportEmail = "support@getportal.co"
    let pricesUpdateInterval = 60
    let fiatCurrenciesUpdateInterval = 3600
    let keychainStorageID: String = "com.portal.keychain.service"
    let testMode = true

    var infuraCredentials: (id: String, secret: String?) {
        let id = "7bffa4b191da4e9682d4351178c4736e"//(Bundle.main.object(forInfoDictionaryKey: "InfuraProjectId") as? String) ?? ""
        let secret = "5dedf9a8a4c4477687cfac3debbc23c6"//Bundle.main.object(forInfoDictionaryKey: "InfuraProjectSecret") as? String
        return (id: id, secret: secret)
    }

    var etherscanKey: String {
        "PYPJHJFA2MUT12KPTT8FCKPAMGHTRDQICB"
        //(Bundle.main.object(forInfoDictionaryKey: "EtherscanApiKey") as? String) ?? ""
    }

    var coinPaprikaApiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "CoinPaprikaApiKey") as? String) ?? ""
    }
        
    var btcCoreRpcUrl: String {
        (Bundle.main.object(forInfoDictionaryKey: "BtcCoreRpcUrl") as? String) ?? ""
    }
    
    var fixerApiKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "FixerApiKey") as? String) ?? ""
    }
    
    var mixpanelToken: String {
        (Bundle.main.object(forInfoDictionaryKey: "MixpanelToken") as? String) ?? ""
    }

    let currencyCodes: [String] = ["USD", "EUR", "GBP", "JPY"]
    let feeRateAdjustedForCurrencyCodes: [String] = ["USD", "EUR"]
}
