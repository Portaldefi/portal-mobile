//
//  AppConfigProvider.swift
//  Portal
//
//  Created by Farid on 15.07.2021.
//

import Foundation

class AppConfigProvider: IAppConfigProvider {
    enum Network {
        case mainnet, testnet, playnet
    }
    
    let companyWebPageLink = "https://getportal.co"
    let appWebPageLink = "https://getportal.co"
    let appGitHubLink = ""
    let reportEmail = "support@getportal.co"
    let pricesUpdateInterval = 60
    let fiatCurrenciesUpdateInterval = 3600
    let keychainStorageID: String = "com.portal.keychain.service"
    let rafaSocketUrl: String = "wss://api.rafa.ai/v1/data/feed/websocket"
    let forexUrl: String = "https://api.rafa.ai/v1/data/feed/forex"
    let network: Network = .playnet

    var infuraCredentials: (id: String, secret: String?) {
        let id = (Bundle.main.object(forInfoDictionaryKey: "InfuraProjectId") as? String) ?? ""
        let secret = Bundle.main.object(forInfoDictionaryKey: "InfuraProjectSecret") as? String
        return (id: id, secret: secret)
    }

    var etherscanKey: String {
        (Bundle.main.object(forInfoDictionaryKey: "EtherscanApiKey") as? String) ?? ""
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
    
    var rafaToken: String {
        (Bundle.main.object(forInfoDictionaryKey: "RafaToken") as? String) ?? ""
    }
    
    var rafaUser: String {
        (Bundle.main.object(forInfoDictionaryKey: "RafaUsername") as? String) ?? ""
    }
    
    var rafaPass: String {
        (Bundle.main.object(forInfoDictionaryKey: "RafaPassword") as? String) ?? ""
    }

    let currencyCodes: [String] = ["USD", "EUR", "GBP", "JPY"]
    let feeRateAdjustedForCurrencyCodes: [String] = ["USD", "EUR"]
}
