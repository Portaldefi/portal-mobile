//
//  EvmLightningSwapPlaynetTest.swift
//  PortalTests
//
//  Created by farid on 18.10.2023.
//

import XCTest
import Combine
import PortalSwapSDK
import Promises
import Web3

final class EvmLightningSwapPlaynetTest: XCTestCase {
    private var sut: EvmLightningSwapPlaynetSample!
    private var subscriptions = Set<AnyCancellable>()
    
    override func setUpWithError() throws {

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        subscriptions.removeAll()
    }
    
    func test_01_PerformSwapBetweenAliceAndBob() async throws {
        sut = try await EvmLightningSwapPlaynetSample()
        
        var alicesSwap: Swap?
        var bobsSwap: Swap?
        
        let swapPromise = expectation(description: "Successefuly execute swap between Alice and Bob")
                       
        sut.alice.on("swap.received", { args in
            if let data = args as? [Swap], let swap = data.first {
                alicesSwap = swap
            }
        })
        .store(in: &subscriptions)
        
        sut.alice.on("order.closed", { _ in
            XCTFail("Alice received order closed")
        })
        .store(in: &subscriptions)
        
        sut.bob.on("swap.received", { args in
            if let data = args as? [Swap], let swap = data.first {
                bobsSwap = swap
            }
        })
        .store(in: &subscriptions)
                
        sut.bob.on("order.closed", { _ in
            XCTFail("Bob received order closed")
        })
        .store(in: &subscriptions)
                
        sut.bob.on("swap.completed", { _ in
            XCTAssertNotNil(alicesSwap)
            XCTAssertNotNil(bobsSwap)
            
            swapPromise.fulfill()
        })
        .store(in: &subscriptions)
        
        sut.start().then { [unowned self] _ in
            let aliceOrderUid = self.sut.alice.id
            let aliceOrderSide: Order.OrderSide = .ask

            self.sut.aliceSubmitLimitOrder().then { order in
                XCTAssertNotNil(order)
                XCTAssertEqual(order.uid, aliceOrderUid)
                XCTAssertEqual(order.type, .limit)
                XCTAssertEqual(order.side, aliceOrderSide)
                XCTAssertEqual(order.baseAsset, "BTC")
                XCTAssertEqual(order.baseQuantity, 2500)
                XCTAssertEqual(order.baseNetwork, "lightning.btc")
                XCTAssertEqual(order.quoteAsset, "ETH")
                XCTAssertEqual(order.quoteQuantity, 10000)
                XCTAssertEqual(order.quoteNetwork, "ethereum")
                XCTAssertEqual(order.status, .created)
            }
            .catch { error in
                XCTFail("Submitting Alice order promise was rejected with error: \(error)")
            }
            
            Thread.sleep(forTimeInterval: 1)
                    
            let bobOrderUid = self.sut.bob.id
            let bobOrderSide: Order.OrderSide = .bid
            
            self.sut.bobSubmitLimitOrder().then { order in
                XCTAssertNotNil(order)
                XCTAssertEqual(order.uid, bobOrderUid)
                XCTAssertEqual(order.type, .limit)
                XCTAssertEqual(order.side, bobOrderSide)
                XCTAssertEqual(order.baseAsset, "BTC")
                XCTAssertEqual(order.baseQuantity, 2500)
                XCTAssertEqual(order.baseNetwork, "lightning.btc")
                XCTAssertEqual(order.quoteAsset, "ETH")
                XCTAssertEqual(order.quoteQuantity, 10000)
                XCTAssertEqual(order.quoteNetwork, "ethereum")
                XCTAssertEqual(order.status, .created)
            }
            .catch { error in
                XCTFail("Submitting Bob order promise was rejected with error: \(error)")
            }
        }
        
        await fulfillment(of: [swapPromise], timeout: 60)
    }
}
