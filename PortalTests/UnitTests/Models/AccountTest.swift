//
//  AccountTest.swift
//  PortalTests
//
//  Created by farid on 21.08.2023.
//

import XCTest
@testable import Portal

final class AccountTest: XCTestCase {
    private var sut: Account!
    private let accountID = UUID().uuidString
    private let accountIndex: Int = Int.random(in: 1...1000)
    private let accountName = "TestAccountName"
    private let accountKey = "TestAccountKey"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sut = Account(id: accountID, index: accountIndex, name: accountName, key: accountKey)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
    }

    func testAccountID() throws {
        XCTAssertEqual(sut.id, accountID, "Account ID doesn't match")
    }
    
    func testAccountIndex() throws {
        XCTAssertEqual(sut.index, accountIndex, "Account Index doesn't match")
    }
    
    func testAccountName() throws {
        XCTAssertEqual(sut.name, accountName, "Account Name doesn't match")
    }
    
    func testAccountKey() throws {
        XCTAssertEqual(sut.rootKey, accountKey, "Account Key doesn't match")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
