//
//  TxFeesText.swift
//  PortalTests
//
//  Created by farid on 22.08.2023.
//

import XCTest
@testable import Portal

final class TxFeesText: XCTestCase {
    private var sut: TxFees!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDescription() throws {
        sut = TxFees.fast
        XCTAssertEqual(sut.description, "Fast ~ 10 mins")
        sut = TxFees.normal
        XCTAssertEqual(sut.description, "Normal ~ 30 mins")
        sut = TxFees.slow
        XCTAssertEqual(sut.description, "Slow ~ 60 mins")
        sut = TxFees.custom
        XCTAssertEqual(sut.description, "Not implemented")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
