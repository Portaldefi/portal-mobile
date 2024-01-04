//
//  MockedAdapter.swift
//  Portal
//
//  Created by farid on 2/21/23.
//

import Foundation
import Combine
import BitcoinDevKit

class MockedAdapter: IAdapter, ISendBitcoinAdapter, ITransactionsAdapter, IDepositAdapter, IBalanceAdapter {
    var onTxsUpdate: AnyPublisher<Void, Never> = Just(()).eraseToAnyPublisher()
    
    var pubKey: String {
        "tb1q3ds30e5p59x9ryee4e2kxz9vxg5ur0tjsv0ug3"
    }
    
//    var L1Balance: Decimal { 0.003 }
    
    func send(amount: Decimal, address: String) throws -> TransactionRecord {
        TransactionRecord.mocked(confirmed: false)
    }
    
    var state: AdapterState = .synced
    
    var balanceStateUpdated: AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
    
    var balanceUpdated: AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
    
    var receiveAddress: String = "tb1q3ds30e5p59x9ryee4e2kxz9vxg5ur0tjsv0ug3"
        
    var balance: Decimal = 1
    
    func validate(address: String) throws {
        
    }
    
    func fee(max: Bool, address: String, amount: Decimal, fee: Int?) throws -> UInt64? {
        1000
    }
    
    func send(amount: Decimal, address: String, fee: Int?) throws -> TransactionRecord {
        TransactionRecord.mocked(confirmed: false)
    }
    
    func sendMax(address: String, fee: Int?) throws -> TransactionRecord {
        TransactionRecord.mocked(confirmed: false)
    }
    
    func rawTransaction(amount: UInt64, address: String) throws -> Transaction {
        try! Transaction(transactionBytes: [])
    }
    
    func start() {
        
    }
    
    func stop() {
        
    }
    
    func refresh() {
        
    }
    
    var transactionRecords: [TransactionRecord] {
        [TransactionRecord.mocked(confirmed: true)]
    }
    
    var blockchainHeight: Int32 = 0
}
