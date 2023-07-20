//
//  AdapterManagerTest.swift
//  PortalTests
//
//  Created by farid on 14.07.2023.
//

import XCTest
@testable import Portal
import Combine

final class AdapterManagerTest: XCTestCase {
    
    private var sut: AdapterManager!
    private let adapterFactory = MockedAdapterFactory()
    private let walletManager = WalletManager.mocked
    private let mockedWallet = Wallet.mocked()
    private var subscriptions = Set<AnyCancellable>()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sut = AdapterManager(adapterFactory: adapterFactory, walletManager: walletManager)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
    }

    func testAdapterReady() throws {
        XCTAssertTrue(sut.adapterReady.value)
    }
    
    func testAdapterForWallet() throws {
        let adapter = sut.adapter(for: mockedWallet)
        XCTAssertNotNil(adapter, "Adapter is nil")
    }
    
    func testAdapterForCoin() throws {
        let adapter = sut.adapter(for: .bitcoin())
        XCTAssertNotNil(adapter, "Adapter for coin is nil")
    }
    
    func testBalanceAdapterForWallet() throws {
        let adapter = sut.balanceAdapter(for: mockedWallet)
        XCTAssertNotNil(adapter, "Balance adapter for wallet is nil")
    }
    
    func testTransactionsAdapterForWallet() throws {
        let adapter = sut.transactionsAdapter(for: mockedWallet)
        XCTAssertNotNil(adapter, "Transactions adapter for wallet is nil")
    }

    func testDepositAdapterForWallet() throws {
        let adapter = sut.depositAdapter(for: mockedWallet)
        XCTAssertNotNil(adapter, "Deposit adapter for wallet is nil")
    }
    
    func testRefreshAdapters() throws {
        sut.refreshAdapters(wallets: walletManager.activeWallets)
        let adapter = sut.adapter(for: .bitcoin())
        XCTAssertNotNil(adapter, "Adapter for coin is nil after refresh")
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
