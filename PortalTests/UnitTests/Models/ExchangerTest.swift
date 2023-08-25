//
//  ExchangerTest.swift
//  PortalTests
//
//  Created by farid on 22.08.2023.
//

import XCTest
@testable import Portal

final class ExchangerTest: XCTestCase {
    private var sut: Exchanger!
    private let base: Coin = .bitcoin()
    private let quote: AccountCurrency = .fiat(.init(code: "USD"))
    private let price: Decimal = 30000

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sut = Exchanger(base: base, quote: quote, price: price)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
    }

    func testBase() throws {
        XCTAssertEqual(sut.base, base, "Base isn't correct")
    }
    
    func testQuote() throws {
        XCTAssertEqual(sut.quote, quote, "Quote isn't correct")
    }
    
    func testPrice() throws {
        XCTAssertEqual(sut.price, price, "Price isn't correct")
    }
    
    func testBaseAmountString() throws {
        sut.side = .base
        XCTAssertEqual(sut.baseAmountString, "0", "Base amount string isn't correct")
        let testAmount = "0.0001"
        sut.amount.string = testAmount
        XCTAssertEqual(sut.baseAmountString, testAmount, "Base amount string isn't correct")
        sut.side = .quote
        XCTAssertEqual(sut.baseAmountString, testAmount, "Base amount string isn't correct")
    }
    
    func testQuoteAmountString() throws {
        sut.side = .base
        XCTAssertEqual(sut.quoteAmountString, "0.0", "Quote amount string isn't correct")
        let testAmount = "0.0001"
        sut.amount.string = testAmount
        XCTAssertEqual(sut.quoteAmountString, "3.0", "Quote amount string isn't correct")
        sut.side = .quote
        XCTAssertEqual(sut.quoteAmountString, "3.0", "Quote amount string isn't correct")
    }
    
    func testBaseAmountDecimal() throws {
        sut.side = .base
        XCTAssertEqual(sut.baseAmountDecimal, 0, "Base amount decimal isn't correct")
        let testAmount = "0.0001"
        sut.amount.string = testAmount
        XCTAssertEqual(sut.baseAmountDecimal, 0.0001, "Base amount decimal isn't correct")
        sut.side = .quote
        XCTAssertEqual(sut.baseAmountDecimal, 0.0001, "Base amount decimal isn't correct")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
