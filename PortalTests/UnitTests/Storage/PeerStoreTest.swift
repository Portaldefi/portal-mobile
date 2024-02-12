//
//  PortalTest.swift
//  PortalTests
//
//  Created by farid on 14.07.2023.
//

import XCTest
@testable import Portal

final class PeerStoreTest: XCTestCase {
    
    private var testPeer: Peer!

    override func setUpWithError() throws {
        super.setUp()
        
        let name = "TestPeer"
        let pubKey = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let host = "127.0.0.2"
        let port: UInt16 = 9742
                
        testPeer = Peer(
            peerPubKey: pubKey,
            name: name,
            connectionInformation: .init(hostname: host, port: port)
        )
    }

    override func tearDownWithError() throws {
        PeerStore.clearPeersDocumentsDirectory()
        testPeer = nil
        super.tearDown()
    }

    func testSave() {
        let expectation = XCTestExpectation(description: "Saving peers")
        
        PeerStore.save(peers: [testPeer]) { result in
            switch result {
            case .success(let count):
                XCTAssertEqual(count, 1, "Expected to save 1 peer.")
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Save failed with error: \(error)")
            }
        }
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLoad() throws {
        //saving one peer
//        PeerStore.save(peers: [testPeer]) { _ in }
//
//        let expectation = XCTestExpectation(description: "Loading peers")
//
//        PeerStore.load { result in
//            switch result {
//            case .success(let peers):
//                XCTAssertTrue(peers.contains(where: { (key: String, value: Peer) in
//                    self.testPeer == value
//                }))
//                expectation.fulfill()
//            case .failure(let error):
//                XCTFail("Load failed with error: \(error)")
//            }
//        }
//        wait(for: [expectation], timeout: 5.0)
    }
    
    func testClearPeersDocumentsDirectory() {
        PeerStore.clearPeersDocumentsDirectory()
        // TODO: Check if the directory was cleared
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
