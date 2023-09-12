//
//  FiatCurrencyTest.swift
//  PortalTests
//
//  Created by farid on 26.07.2023.
//

import XCTest
@testable import Portal

final class FiatCurrencyTest: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNames() throws {
        let currencies = FiatCurrency.names
        for (code, expectedName) in currencies {
            let currency = FiatCurrency(code: code)
            XCTAssertEqual(currency.name, expectedName, "Failed for currency code: \(code)")
        }
    }
    
    func testSymbols() throws {
        let currencies = FiatCurrency.names
        for currency in currencies {
            let currency = FiatCurrency(code: currency.key)
            XCTAssertNotEqual(currency.symbol, "-", "Failed for currency symbol: \(currency.code)")
        }
    }

    func testNamesPerformance() throws {
        // This is an example of a performance test case.
        self.measure {
            do {
                try testNames()
            } catch {
                XCTFail("Error thrown: \(error)")
            }
        }
    }
    
    func testSymbolsPerformance() throws {
        // This is an example of a performance test case.
        self.measure {
            do {
                try testSymbols()
            } catch {
                XCTFail("Error thrown: \(error)")
            }
        }
    }

}
