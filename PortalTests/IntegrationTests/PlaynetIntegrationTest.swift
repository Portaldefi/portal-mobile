//
//  PlaynetIntegrationTest.swift
//  PortalTests
//
//  Created by farid on 25.08.2023.
//

import XCTest

final class PlaynetIntegrationTest: XCTestCase {
    private var sut: PlaynetIntergrationSample!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sut = PlaynetIntergrationSample()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
    }

    func testPlaynetIntegration() async throws {
        try await sut.testLDKSetupWithPlaynet()
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
