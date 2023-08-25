//
//  WalletItemTest.swift
//  PortalTests
//
//  Created by farid on 18.08.2023.
//

import XCTest
@testable import Portal

final class WalletItemTest: XCTestCase {
    private var sut: WalletItem!
    private let coin: Coin = .bitcoin()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sut = WalletItem(coin: coin)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
    }

    func testCoin() throws {
        XCTAssertEqual(sut.coin, coin, "Coin doesn't match")
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
