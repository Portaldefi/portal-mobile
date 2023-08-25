//
//  CoinManagerTest.swift
//  PortalTests
//
//  Created by farid on 14.07.2023.
//

import XCTest
@testable import Portal
import Combine

final class CoinManagerTest: XCTestCase {
    
    private var sut: CoinManager!
    private let accountManager = MockedAccountManager()
    private let coinStorage = MockedCoinStorage()
    private let userSettings = MockedPortalSettings()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sut = CoinManager(storage: coinStorage, accountManager: accountManager, userSettings: userSettings)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
    }

//    func testWalletCoins() throws {
//        XCTAssertEqual(sut.walletCoins.count, 2)
//        
//        coinStorage.addErc20()
//        
//        XCTAssertEqual(sut.walletCoins.count, 2 + coinStorage.erc20.count)
//    }
    
    func testAvaliableCoins() throws {
        XCTAssertEqual(sut.avaliableCoins.count, 0)
        
        coinStorage.addErc20()
        
        XCTAssertEqual(sut.avaliableCoins.count, coinStorage.erc20.count)
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
