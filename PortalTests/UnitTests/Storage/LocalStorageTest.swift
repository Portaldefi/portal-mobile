//
//  LocalStorageTest.swift
//  UnitTestsMacOS
//
//  Created by farid on 1/23/22.
//

import XCTest
@testable import Portal

class LocalStorageTest: XCTestCase {
    
    private var sut: LocalStorage!
    private var userDefaults: UserDefaults!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        userDefaults = UserDefaults.init(suiteName: #file)
        userDefaults.removePersistentDomain(forName: #file)
        
        sut = LocalStorage(storage: userDefaults)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        
        userDefaults = nil
        sut = nil
    }
    
    func testGetCurrentAccountID() throws {
        XCTAssertNil(sut.getCurrentAccountID())
        
        let accountId = UUID().uuidString
        
        userDefaults.setValue(accountId, forKey: LocalStorage.currentAccountIDKey)
        
        XCTAssertNotNil(sut.getCurrentAccountID())
        XCTAssertEqual(accountId, sut.getCurrentAccountID())
    }
    
    func testSetCurrentAccountID() throws {
        XCTAssertNil(sut.getCurrentAccountID())
        
        let accountId = UUID().uuidString
        
        sut.setCurrentAccountID(accountId)
        
        XCTAssertNotNil(userDefaults.value(forKey: LocalStorage.currentAccountIDKey))
        XCTAssertEqual(accountId, userDefaults.string(forKey: LocalStorage.currentAccountIDKey))
    }
    
    func testRemoveCurrenctAccountId() throws {
        XCTAssertNil(userDefaults.object(forKey: LocalStorage.currentAccountIDKey))

        let accountId = UUID().uuidString
        
        userDefaults.setValue(accountId, forKey: LocalStorage.currentAccountIDKey)
        
        XCTAssertNotNil(userDefaults.object(forKey: LocalStorage.currentAccountIDKey), "Account id isn't saved")
        
        sut.removeCurrentAccountID()
        
        XCTAssertNil(userDefaults.object(forKey: LocalStorage.currentAccountIDKey))
    }
    
    func testAddSyncedExchange() throws {
        XCTAssertEqual(sut.syncedExchangesIds.isEmpty, true)
        
        var testsCount: Int = 0
        
        for _ in 1...Int.random(in: 4...10) {
            sut.addSyncedExchange(id: UUID().uuidString)
            testsCount += 1
        }
        
        XCTAssertEqual(sut.syncedExchangesIds.count, testsCount)
    }
    
    func testRemoveSyncedExchange() throws {
        var testsCount: Int = 0
        
        for _ in 1...Int.random(in: 1...10) {
            sut.addSyncedExchange(id: UUID().uuidString)
            testsCount += 1
        }
        
        let randomExchangeId = sut.syncedExchangesIds.randomElement()
        
        XCTAssertNotNil(randomExchangeId, "id is nil")
        
        sut.removeSyncedExchange(id: randomExchangeId!)
        
        XCTAssertEqual(sut.syncedExchangesIds.count, testsCount - 1)
        XCTAssertEqual(sut.syncedExchangesIds.contains(randomExchangeId!), false)
    }
    
    func testIsFirstLaunch() throws {
        XCTAssertEqual(sut.isFirstLaunch, true)
        
        sut.incrementAppLaunchesCouner()
        
        XCTAssertEqual(sut.isFirstLaunch, false)
    }
    
    func testIncrementAppLaunchesCouner() throws {
        XCTAssertEqual(userDefaults.integer(forKey: LocalStorage.appLaunchesCountKey), 0)
        
        sut.incrementAppLaunchesCouner()
        
        XCTAssertEqual(userDefaults.integer(forKey: LocalStorage.appLaunchesCountKey), 1)
    }
}
