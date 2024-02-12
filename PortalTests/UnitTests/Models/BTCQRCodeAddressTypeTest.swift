//
//  BTCQRCodeAddressTypeTest.swift
//  PortalTests
//
//  Created by farid on 22.08.2023.
//

import XCTest
@testable import Portal

final class BTCQRCodeAddressTypeTest: XCTestCase {
    private var sut: BTCQRCodeAddressType!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTitle() throws {
        sut = .onChain
        XCTAssertEqual(sut.title, "On Chain", "Title is wrong")
        sut = .lightning
        XCTAssertEqual(sut.title, "Lightning", "Title is wrong")
        sut = .unified
        XCTAssertEqual(sut.title, "Unified", "Title is wrong")
    }
    
    func testDescription() throws {
        sut = .onChain
        XCTAssertEqual(sut.description, "Slower. Higher fees. Most services support it.", "Description is wrong")
        sut = .lightning
        XCTAssertEqual(sut.description, "Instant, with minimal fees. But not all services support it.", "Description is wrong")
        sut = .unified
        XCTAssertEqual(sut.description, "An unified QR for both Lightning & On Chain. Most services don’t support it, yet.", "Description is wrong")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
