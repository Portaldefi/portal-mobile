//
//  CoinTest.swift
//  PortalTests
//
//  Created by farid on 26.07.2023.
//

import XCTest
@testable import Portal
import PortalUI
import SwiftUI
import Factory

struct MockedConfigProvider: IAppConfigProvider {
    var companyWebPageLink: String = ""
    var appWebPageLink: String = ""
    var appGitHubLink: String = ""
    var reportEmail: String = ""
    var pricesUpdateInterval: Int = 5
    var fiatCurrenciesUpdateInterval: Int = 5
    var keychainStorageID: String = ""
    var mixpanelToken: String = ""
    var infuraCredentials: (id: String, secret: String?) = (id: String(), secret: nil)
    var etherscanKey: String = ""
    var fixerApiKey: String = ""
    var coinPaprikaApiKey: String = ""
    var btcCoreRpcUrl: String = ""
    var currencyCodes: [String] = []
    var feeRateAdjustedForCurrencyCodes: [String] = []
    var rafaToken: String = ""
    var rafaUser: String = ""
    var rafaPass: String = ""
    var rafaSocketUrl: String = ""
    var forexUrl: String = ""
    var network: AppConfigProvider.Network
}

final class CoinTest: XCTestCase {

    func testCoinProperties() {
        for network in AppConfigProvider.Network.allCases {
            Container.configProvider.register {
                MockedConfigProvider(network: network)
            }
            
            let bitcoin = Coin(type: .bitcoin, code: "BTC", name: "Bitcoin", decimal: 8, iconUrl: "someURL")
            XCTAssertEqual(bitcoin.unit, "BTC")
            XCTAssertEqual(bitcoin.description, "Chain")
            XCTAssertEqual(bitcoin.color, Color(red: 242/255, green: 169/255, blue: 0/255))
            XCTAssertEqual(bitcoin.chainIcon, Asset.chainIcon)
            
            let lightningBitcoin = Coin(type: .lightningBitcoin, code: "BTC", name: "Lightning Bitcoin", decimal: 8, iconUrl: "someURL")
            XCTAssertEqual(lightningBitcoin.unit, "BTC")
            XCTAssertEqual(lightningBitcoin.description, "Lightning")
            XCTAssertEqual(lightningBitcoin.color, Color.white)
            XCTAssertEqual(lightningBitcoin.chainIcon, Asset.lightningIcon)
            
            let ethereum = Coin(type: .ethereum, code: "ETH", name: "Ethereum", decimal: 18, iconUrl: "someURL")
            XCTAssertEqual(ethereum.unit, "ETH")
            XCTAssertEqual(ethereum.description, "Chain")
            XCTAssertEqual(ethereum.color, Color.blue)
            XCTAssertEqual(ethereum.chainIcon, Asset.chainIcon)
            
            let erc20 = Coin(type: .erc20(address: "0x..."), code: "ERC20", name: "ERC20 Token", decimal: 18, iconUrl: "someURL")
            XCTAssertEqual(erc20.unit, "ERC20")
            XCTAssertEqual(erc20.description, "Chain")
            XCTAssertEqual(erc20.color, Color.white)
            XCTAssertEqual(erc20.chainIcon, Asset.chainIcon)
            
            switch network {
            case .mainnet:
                XCTAssertEqual(bitcoin.network, "Bitcoin")
                XCTAssertEqual(lightningBitcoin.network, "Lightning")
                XCTAssertEqual(ethereum.network, "Ethereum")
                XCTAssertEqual(erc20.network, "ERC-20")
            case .testnet:
                XCTAssertEqual(bitcoin.network, "Testnet")
                XCTAssertEqual(lightningBitcoin.network, "Lightning")
                XCTAssertEqual(ethereum.network, "Sepolia")
                XCTAssertEqual(erc20.network, "ERC-20")
            case .playnet:
                XCTAssertEqual(bitcoin.network, "Regtest")
                XCTAssertEqual(lightningBitcoin.network, "Lightning")
                XCTAssertEqual(ethereum.network, "Developer")
                XCTAssertEqual(erc20.network, "ERC-20")
            }
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            testCoinProperties()
        }
    }

}
