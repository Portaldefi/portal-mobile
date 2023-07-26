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

final class CoinTest: XCTestCase {

    func testCoinProperties() {
        let bitcoin = Coin(type: .bitcoin, code: "BTC", name: "Bitcoin", decimal: 8, iconUrl: "someURL")
        XCTAssertEqual(bitcoin.network, "Lightning")
        XCTAssertEqual(bitcoin.unit, "BTC")
        XCTAssertEqual(bitcoin.description, "Chain")
        XCTAssertEqual(bitcoin.color, Color(red: 242/255, green: 169/255, blue: 0/255))
        XCTAssertEqual(bitcoin.chainIcon, Asset.chainIcon)
        
        let lightningBitcoin = Coin(type: .lightningBitcoin, code: "BTC", name: "Lightning Bitcoin", decimal: 8, iconUrl: "someURL")
        XCTAssertEqual(lightningBitcoin.network, "Lightning")
        XCTAssertEqual(lightningBitcoin.unit, "sats")
        XCTAssertEqual(lightningBitcoin.description, "Lightning")
        XCTAssertEqual(lightningBitcoin.color, Color.white)
        XCTAssertEqual(lightningBitcoin.chainIcon, Asset.lightningIcon)
        
        let ethereum = Coin(type: .ethereum, code: "ETH", name: "Ethereum", decimal: 18, iconUrl: "someURL")
        XCTAssertEqual(ethereum.network, "Ethereum")
        XCTAssertEqual(ethereum.unit, "ETH")
        XCTAssertEqual(ethereum.description, "Chain")
        XCTAssertEqual(ethereum.color, Color.blue)
        XCTAssertEqual(ethereum.chainIcon, Asset.chainIcon)
        
        let erc20 = Coin(type: .erc20(address: "0x..."), code: "ERC20", name: "ERC20 Token", decimal: 18, iconUrl: "someURL")
        XCTAssertEqual(erc20.network, "Ethereum")
        XCTAssertEqual(erc20.unit, "ERC20")
        XCTAssertEqual(erc20.description, "Chain")
        XCTAssertEqual(erc20.color, Color.white)
        XCTAssertEqual(erc20.chainIcon, Asset.chainIcon)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
