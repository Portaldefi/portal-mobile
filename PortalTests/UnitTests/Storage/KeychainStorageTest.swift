//
//  KeychainStorageTest.swift
//  UnitTestsMacOS
//
//  Created by farid on 1/21/22.
//

import XCTest
@testable import Portal
import KeychainAccess

class KeychainStorageTest: XCTestCase {
    
    private let keychain = Keychain(service: "UnitTestsKeychainService")
    private var sut: KeychainStorage!
    private let key = "TestKey"
    private let text = "Test"
    private let data = "TestString".data(using: .utf8)!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        sut = KeychainStorage(keychain: keychain)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try keychain.removeAll()
        sut = nil
    }
    
    func testStringForKey() throws {
        XCTAssertNil(sut.string(for: key))
                     
        try keychain.set(text, key: key)
                     
        XCTAssertNotNil(sut.string(for: key))
        XCTAssertEqual(text, sut.string(for: key))
    }
    
    func testSaveStringForKey() throws {
        sut.save(string: text, key: key)
        XCTAssertEqual(keychain[key], text)
    }
    
    func testDataForKey() throws {
        XCTAssertNil(sut.data(for: key))
        
        try keychain.set(data, key: key)
        
        XCTAssertNotNil(sut.data(for: key))
        XCTAssertEqual(sut.data(for: key), data)
    }
    
    func testSaveDataForKey() throws {
        XCTAssertNil(sut.data(for: key))
        
        sut.save(data: data, key: key)
        
        XCTAssertEqual(keychain[data: key], data)
    }
    
    func testRemoveAll() throws {
        sut.save(data: data, key: key)
        
        XCTAssertNotEqual(keychain.allKeys().count, 0)

        try sut.clear()
        
        XCTAssertEqual(keychain.allKeys().count, 0)
    }
    
    func testRemoveKey() throws {
        try keychain.set(text, key: key)

        XCTAssertNotNil(keychain[key], "string isn't saved to keychain")
        
        try sut.remove(key: key)
        
        XCTAssertNil(keychain[key], "string isn't removed from keychain")
    }
    
    func testRecoverStringArrayForKey() throws {
        XCTAssertNil(sut.recoverStringArray(for: key), "Unexpected array for key")
        
        let stringsArray = ["First", "Second", "Third"]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: stringsArray, options: JSONSerialization.WritingOptions())
        
        sut.save(data: jsonData, key: key)
        
        let recoveredStringArray = sut.recoverStringArray(for: key)
        
        XCTAssertEqual(stringsArray, recoveredStringArray)
    }
    
    func testLosslessStringConvertibleValueForKey() throws {
        XCTAssertNil(sut.value(for: key), "value isn't nil")
        
        let arrayString = ["First", "Second", "Third"].joined(separator: " ")
        
        try keychain.set(arrayString, key: key)
        
        let updatedValueForKey: String? = sut.value(for: key)
        
        XCTAssertNotNil(updatedValueForKey, "updated value is nil")
        XCTAssertEqual(updatedValueForKey, arrayString)
    }
    
    func testDataValueForKey() throws {
        XCTAssertNil(sut.value(for: key), "value isn't nil")
                
        try keychain.set(data, key: key)
        
        XCTAssertEqual(sut.value(for: key), data)
        
        try sut.set(value: nil, for: key)
        
        XCTAssertNil(keychain[key])
    }
    
    func testSetLosslessStringConvertible() throws {
        XCTAssertNil(keychain[key])
        
        try sut.set(value: text, for: key)
        
        XCTAssertNotNil(keychain[key])
        XCTAssertEqual(keychain[key], text.description)
        
        try sut.set(value: nil, for: key)
        
        XCTAssertNil(keychain[key])
    }
    
    func testRemoveValueForKey() throws {
        try keychain.set(text, key: key)
        
        XCTAssertNotNil(keychain[key], "Empty")
        
        try sut.removeValue(for: key)
        
        XCTAssertNil(keychain[key], "Not removed")
    }
}
