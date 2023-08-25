//
//  QRCodeItemTest.swift
//  PortalTests
//
//  Created by farid on 21.08.2023.
//

import XCTest
@testable import Portal

final class QRCodeItemTest: XCTestCase {
    private var sut: QRCodeItem!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sut = nil
    }

    func testUnsupportedType() throws {
        sut = QRCodeItem.unsupported
        XCTAssertEqual(sut.type, .unsupported)
        XCTAssertEqual(sut.title, "Unsupported item", "Item title doesn't match")
        XCTAssertEqual(sut.description, String(), "Item description doesn't match")
    }
    
    func testBip21Type() throws {
        let testAddress = "TestAddress"
        let testAmount = "1000"
        let testMessage = "TestMessage"
        
        sut = QRCodeItem.bip21(address: testAddress, amount: testAmount, message: testMessage)
        
        XCTAssertEqual(sut.type, .bip21(address: testAddress, amount: testAmount, message: testMessage))
        XCTAssertEqual(sut.title, "Bitcoin Address", "Item title doesn't match")
        XCTAssertEqual(sut.description, "Chain", "Item description doesn't match")
    }
    
    func testBolt11Type() throws {
        let invoice = "TestInvoice"
        
        sut = QRCodeItem.bolt11(invoice: invoice)
        
        XCTAssertEqual(sut.type, .bolt11(invoice: invoice))
        XCTAssertEqual(sut.title, "Bitcoin Payment Request", "Item title doesn't match")
        XCTAssertEqual(sut.description, "Lightning", "Item description doesn't match")
    }
    
    func testBolt12Type() throws {
        let offer = "TestOffer"
        
        sut = QRCodeItem(type: .bolt12(offer: offer))
        
        XCTAssertEqual(sut.type, .bolt12(offer: offer))
        XCTAssertEqual(sut.title, "Bitcoin Payment Request", "Item title doesn't match")
        XCTAssertEqual(sut.description, "Lightning", "Item description doesn't match")
    }
    
    func testPubKeyType() throws {
        let pubKey = "TestPubKey"
        
        sut = QRCodeItem.publicKey(xpub: pubKey)
        
        XCTAssertEqual(sut.type, .pubKey(xpub: pubKey))
        XCTAssertEqual(sut.title, "Bitcoin Public Key", "Item title doesn't match")
        XCTAssertEqual(sut.description, "Chain", "Item description doesn't match")
    }
    
    func testPrivKeyType() throws {
        let privKey = "TestPrivKey"
        
        sut = QRCodeItem.privateKey(key: privKey)
        
        XCTAssertEqual(sut.type, .privKey(key: privKey))
        XCTAssertEqual(sut.title, "Bitcoin Private Key", "Item title doesn't match")
        XCTAssertEqual(sut.description, "Chain", "Item description doesn't match")
    }
    
    func testEthType() throws {
        let address = "TestEthAddress"
        let amount = "0.0001"
        let message = "TestMessage"
        
        sut = QRCodeItem.eth(address: address, amount: amount, message: message)
        
        XCTAssertEqual(sut.type, .eth(address: address, amount: amount, message: message))
        XCTAssertEqual(sut.title, "Ethereum Address", "Item title doesn't match")
        XCTAssertEqual(sut.description, "Chain", "Item description doesn't match")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
