//
//  TxTypeTest.swift
//  PortalTests
//
//  Created by farid on 22.08.2023.
//

import XCTest
@testable import Portal

final class TxTypeTest: XCTestCase {
    private var sut: TxType!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
    }

    func testDescription() throws {
        sut = TxType.unknown
        XCTAssertEqual(sut.description, "Unknown", "TxType description isn't correct")
        sut = TxType.sent
        XCTAssertEqual(sut.description, "Sent", "TxType description isn't correct")
        sut = TxType.received
        XCTAssertEqual(sut.description, "Received", "TxType description isn't correct")
        sut = TxType.swapped(for: .bitcoin())
        XCTAssertEqual(sut.description, "Swapped for BTC", "TxType description isn't correct")
    }
    
    func testTypeForFilter() throws {
        let nonFilter: TxFilterOption = .none
        XCTAssertEqual(TxType.typeFor(filter: nonFilter), TxType.unknown)
        let successFilter: TxFilterOption = .success
        XCTAssertEqual(TxType.typeFor(filter: successFilter), TxType.unknown)
        let pendingFilter: TxFilterOption = .pending
        XCTAssertEqual(TxType.typeFor(filter: pendingFilter), TxType.unknown)
        let failedFilter: TxFilterOption = .failed
        XCTAssertEqual(TxType.typeFor(filter: failedFilter), TxType.unknown)
        let receivedFilter: TxFilterOption = .received
        XCTAssertEqual(TxType.typeFor(filter: receivedFilter), TxType.received)
        let sendFilter: TxFilterOption = .send
        XCTAssertEqual(TxType.typeFor(filter: sendFilter), TxType.sent)
        let swappedFilter: TxFilterOption = .swapped
        XCTAssertEqual(TxType.typeFor(filter: swappedFilter), TxType.swapped(for: .bitcoin()))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
