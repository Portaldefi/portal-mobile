//
//  AccountStorageTest.swift
//  PortalTests
//
//  Created by farid on 14.07.2023.
//

import XCTest
@testable import Portal
import BitcoinDevKit

final class AccountStorageTest: XCTestCase {
    
    private var sut: AccountStorage!
    private let localStorage = LocalStorage.mocked
    private let secureStorage = KeychainStorage.mocked
    private var accountStorage: IAccountRecordStorage!

    override func setUp() {
        super.setUp()
        
        accountStorage = DBlocalStorage.mocked
        sut = AccountStorage(localStorage: localStorage, secureStorage: secureStorage, accountStorage: accountStorage)
    }

    override func tearDown() {
        sut = nil
        accountStorage = nil
        
        super.tearDown()
    }

    func testActiveAccountRecoveryData() {
        XCTAssertNil(sut.activeAccountRecoveryData, "RecoveryData should be nil")
        
        accountStorage.save(accountRecord: AccountRecord.mocked)
        
        guard let recoveryData = sut.activeAccountRecoveryData else {
            return XCTAssertThrowsError("Recovery data should not be nil")
        }
        let words = recoveryData.words
        XCTAssertEqual(words.count, 12, "Recovery words count isn't correct")
        let salt = recoveryData.salt
        XCTAssertEqual(salt, "test_salt", "Recovery salt isn't correct")
        let recoveryString = recoveryData.recoveryString
        XCTAssertEqual(recoveryString, recoveryData.words.joined(separator: " "), "Recovery string isn't correct")
    }

    func testActiveAccount() {
        XCTAssertNil(sut.activeAccount, "Active account should be nil")

        accountStorage.save(accountRecord: AccountRecord.mocked)
        
        guard let activeAccount = sut.activeAccount else {
            return XCTAssertThrowsError("Active account should not be nil")
        }
        XCTAssertEqual(activeAccount.id, "MockedAccountID", "Active account id isn't correct")
        XCTAssertEqual(activeAccount.name, "Mocked", "Active account name id isn't correct")
    }

    func testAllAccounts() {
        XCTAssertEqual(sut.allAccounts.isEmpty, true, "Accounts should be empty")
        accountStorage.save(accountRecord: AccountRecord.mocked)
        XCTAssertEqual(sut.allAccounts.count, 1, "Accounts array is wrong")
    }

    func testSaveAccount() {
        XCTAssertNil(sut.activeAccount, "Active account should be nil")

        let id = "MockedAccountID"
        let index = 1
        let name = "AdditionalAccountName"
        let key = "AdditionalAccountKey"
        let additionalAccount = Account(id: id, index: index, name: name, key: key)
        let mnemonic = Mnemonic(wordCount: .words12).asString()
        let salt = "salt"
        
        sut.save(account: additionalAccount, mnemonic: mnemonic, salt: salt)
        
        XCTAssertNotNil(sut.activeAccount, "Active account is nil")
        XCTAssertEqual(sut.allAccounts.count, 1, "Accounts array is wrong")
        guard let activeAccount = sut.activeAccount else {
            return XCTAssertThrowsError("Active account should not be nil")
        }
        XCTAssertEqual(activeAccount.id, id, "Active account id is wrong")
        XCTAssertEqual(activeAccount.name, name, "Active account name is wrong")
    }

    func testDeleteAccount() {
        XCTAssertNil(sut.activeAccount, "Active account should be nil")
        accountStorage.save(accountRecord: AccountRecord.mocked)
        XCTAssertNotNil(sut.activeAccount, "Active account should not be nil")
        
        sut.delete(account: Account.mocked)
        XCTAssertNil(sut.activeAccount, "Active account should be nil")
    }

    func testClear() {
        // TODO: Set up your mock objects, call the function, and assert the results
    }

    func testSetCurrentAccount() {
        // TODO: Set up your mock objects, call the function, and assert the results
    }

    func testUpdateAccount() {
        // TODO: Set up your mock objects, call the function, and assert the results
    }
    
}
