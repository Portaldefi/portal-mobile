//
//  AccountCurrencyTest.swift
//  PortalTests
//
//  Created by farid on 26.07.2023.
//

import XCTest
@testable import Portal

final class AccountCurrencyTest: XCTestCase {

    func testAccountCurrencyProperties() {
        let fiatCurrency = FiatCurrency(code: "USD")
        let fiat = AccountCurrency.fiat(fiatCurrency)
        XCTAssertEqual(fiat.symbol, "$")
        XCTAssertEqual(fiat.code, "USD")
        XCTAssertEqual(fiat.name, "United States Dollar")
        XCTAssertEqual(fiat.rate, 1)

        let bitcoin = Coin(type: .bitcoin, code: "BTC", name: "Bitcoin", decimal: 8, iconUrl: "someURL")
        let accountBitcoin = AccountCurrency.coin(bitcoin)
        XCTAssertEqual(accountBitcoin.symbol, "₿")
        XCTAssertEqual(accountBitcoin.code, "BTC")
        XCTAssertEqual(accountBitcoin.name, "Bitcoin")
        XCTAssertEqual(accountBitcoin.rate, 1)

        let ethereum = Coin(type: .ethereum, code: "ETH", name: "Ethereum", decimal: 18, iconUrl: "someURL")
        let accountEthereum = AccountCurrency.coin(ethereum)
        XCTAssertEqual(accountEthereum.symbol, "Ξ")
        XCTAssertEqual(accountEthereum.code, "ETH")
        XCTAssertEqual(accountEthereum.name, "Ethereum")
        XCTAssertEqual(accountEthereum.rate, 1)
        
        let lightningBitcoin = Coin(type: .lightningBitcoin, code: "LBTC", name: "Lightning Bitcoin", decimal: 8, iconUrl: "someURL")
        let accountLightningBitcoin = AccountCurrency.coin(lightningBitcoin)
        XCTAssertEqual(accountLightningBitcoin.symbol, "₿")
        XCTAssertEqual(accountLightningBitcoin.code, "LBTC")
        XCTAssertEqual(accountLightningBitcoin.name, "Lightning Bitcoin")
        XCTAssertEqual(accountLightningBitcoin.rate, 1)

        let erc20 = Coin(type: .erc20(address: "0x123"), code: "ERC20", name: "ERC20 Token", decimal: 18, iconUrl: "someURL")
        let accountERC20 = AccountCurrency.coin(erc20)
        XCTAssertEqual(accountERC20.symbol, "Ξ")
        XCTAssertEqual(accountERC20.code, "ERC20")
        XCTAssertEqual(accountERC20.name, "ERC20 Token")
        XCTAssertEqual(accountERC20.rate, 1)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
