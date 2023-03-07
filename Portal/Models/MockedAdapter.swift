//
//  MockedAdapter.swift
//  Portal
//
//  Created by farid on 2/21/23.
//

import Foundation
import Combine

class MockedAdapter: IAdapter, ISendBitcoinAdapter, ITransactionsAdapter, IDepositAdapter, IBalanceAdapter {
    var state: AdapterState = .synced
    
    var balanceStateUpdated: AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
    
    var balanceUpdated: AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
    
    var receiveAddress: String = "tb1q3ds30e5p59x9ryee4e2kxz9vxg5ur0tjsv0ug3"
    
    var transactionRecords: AnyPublisher<[TransactionRecord], Never> {
        Just([TransactionRecord.mocked]).eraseToAnyPublisher()
    }
    
    var balance: Decimal = 1
    
    func validate(address: String) throws {
        
    }
    
    func fee(max: Bool, address: String, amount: Decimal, fee: Int?) throws -> UInt64? {
        1000
    }
    
    func send(amount: Decimal, address: String, fee: Int?) -> Future<TransactionRecord, Error> {
        Future { promise in
            promise(.success(TransactionRecord.mocked))
        }
    }
    
    func sendMax(address: String, fee: Int?) -> Future<TransactionRecord, Error> {
        Future { promise in
            promise(.success(TransactionRecord.mocked))
        }
    }
    
    func start() {
        
    }
    
    func stop() {
        
    }
    
    func refresh() {
        
    }
    
    var blockchainHeight: Int32 = 0
}
