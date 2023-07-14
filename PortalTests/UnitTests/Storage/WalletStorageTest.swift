//
//  WalletStorageTest.swift
//  UnitTestsMacOS
//
//  Created by farid on 1/21/22.
//

import XCTest
@testable import Portal
import Combine

class WalletStorageTest: XCTestCase {
    
    private var sut: WalletStorage!
    private var subscriptions = Set<AnyCancellable>()
    private let accountManager: IAccountManager = MockedAccountManager()
    private var coinManager = MockedCoinManager()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sut = WalletStorage(coinManager: coinManager, accountManager: accountManager)
        coinManager.addCoins()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        subscriptions.removeAll()
        sut = nil
    }
    
    func testOnActiveAccountUpdateUpdatesWallets() throws {
        XCTAssertEqual(sut.wallets.count, 2)
        
        let promise = expectation(description: "wallets updated")
        
        sut.onWalletsUpdate.sink(receiveValue: { wallets in
            XCTAssertNotNil(wallets, "wallets are nil")
            promise.fulfill()
        })
        .store(in: &subscriptions)
        
        accountManager.onActiveAccountUpdate.send(nil)
        
        wait(for: [promise], timeout: 0.2)
        
        XCTAssertEqual(sut.wallets.count, 2)
    }
    
    func testOnCoinsUpdateUpdatesWallets() throws {
        XCTAssertEqual(sut.wallets.count, 2)

        let promise = expectation(description: "wallets updated")
        
        sut.onWalletsUpdate.sink(receiveValue: { wallets in
            XCTAssertEqual(wallets.count, 0)
            promise.fulfill()
        })
        .store(in: &subscriptions)
        
        coinManager.removeCoins()
        
        wait(for: [promise], timeout: 0.2)
        
        XCTAssertEqual(sut.wallets.count, 0)
    }
    
    func testClearWallets() throws {
        XCTAssertEqual(sut.wallets.count, 2)
        
        sut.clearWallets()
        
        XCTAssertEqual(sut.wallets.count, 0)
    }
}
