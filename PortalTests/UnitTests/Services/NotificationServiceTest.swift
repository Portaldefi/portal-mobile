//
//  NotificationServiceTest.swift
//  UnitTestsMacOS
//
//  Created by farid on 1/25/22.
//

import XCTest
@testable import Portal

class NotificationServiceTest: XCTestCase {
    
    private var sut: NotificationService!
    private let accountManager = MockedAccountManager()
    private let testNotification = PNotification(message: "test")


    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sut = NotificationService(accountManager: accountManager)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
    }
    
    func testDefaultValues() throws {
        XCTAssertEqual(sut.notifications.value.count, 0)
        XCTAssertEqual(sut.newAlerts.value, 0)
        XCTAssertEqual(sut.alertsBeenSeen.value, false)
    }
    
    func testNotify() throws {
        sut.notify(testNotification)
        
        let promise = expectation(description: "Properties are updated")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 0.2)
        
        XCTAssertEqual(sut.newAlerts.value, 1)
        XCTAssertEqual(sut.alertsBeenSeen.value, false)
        XCTAssertEqual(sut.notifications.value.isEmpty, false)
        XCTAssertEqual(sut.notifications.value.count, 1)
        XCTAssertEqual(sut.notifications.value.first, testNotification)
    }
    
    func testMarkAllAlertsViewed() throws {
        sut.notify(testNotification)
        
        let promise = expectation(description: "Properties are updated")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 0.2)
        
        XCTAssertEqual(sut.newAlerts.value, 1)
        XCTAssertEqual(sut.alertsBeenSeen.value, false)
        XCTAssertEqual(sut.notifications.value.isEmpty, false)
        XCTAssertEqual(sut.notifications.value.count, 1)
        XCTAssertEqual(sut.notifications.value.first, testNotification)
        
        sut.markAllAlertsViewed()
        
        XCTAssertEqual(sut.newAlerts.value, 0)
        XCTAssertEqual(sut.alertsBeenSeen.value, true)
    }
    
    func testClearNotification() throws {
        sut.notify(testNotification)
        
        let promise = expectation(description: "Properties are updated")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            promise.fulfill()
        }
        
        wait(for: [promise], timeout: 0.2)
        
        XCTAssertEqual(sut.newAlerts.value, 1)
        XCTAssertEqual(sut.alertsBeenSeen.value, false)
        XCTAssertEqual(sut.notifications.value.isEmpty, false)
        XCTAssertEqual(sut.notifications.value.count, 1)
        XCTAssertEqual(sut.notifications.value.first, testNotification)
        
        sut.clear()
        
        XCTAssertEqual(sut.notifications.value.isEmpty, true)
    }
}
