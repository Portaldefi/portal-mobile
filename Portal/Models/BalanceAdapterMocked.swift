//
//  BalanceAdapterMocked.swift
//  Portal
//
//  Created by farid on 9/29/22.
//

import Foundation
import Combine

class BalanceAdapterMocked: IBalanceAdapter {
    var state: AdapterState = .synced
    var balance: Decimal = 0.00055
    var balanceStateUpdated: AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
    var balanceUpdated: AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
}

class SendAdapterMocked: ISendAdapter {
    func sendMax(to: String, fee: Int?, completion: @escaping (String?, Error?) -> Void) {
        
    }
    
    func send(to: String, amount: String, fee: Int?, completion: @escaping (String?, Error?) -> Void) {
        
    }
}

class SendAssetMockedService: ISendAssetService {
    var balance: Decimal = 1.1
    var spendable: Decimal = 1.1
    var fee: Decimal = 0.0001
    var amount: CurrentValueSubject<Decimal, Never> = CurrentValueSubject<Decimal, Never>(0.001)
    var feeRate: CurrentValueSubject<Int, Never> = CurrentValueSubject<Int, Never>(1)
    var receiverAddress: CurrentValueSubject<String, Never> = CurrentValueSubject<String, Never>("tb1q3ds30e5p59x9ryee4e2kxz9vxg5ur0tjsv0ug3")
    var feeRateProvider: IFeeRateProvider = MockeFeeRateProvider()
    
    init() {
        
    }
    
    func validateAddress() throws {
        
    }
    
    func send() -> Future<Void, Error> {
        Future { promise in
            promise(.success(()))
        }
    }
}

class MockeFeeRateProvider: IFeeRateProvider {
    var recommendedFeeRate: Future<Int, Never> {
        Future { promise in
            promise(.success(10000))
        }
    }
}

class DepositAdapterMocked: IDepositAdapter {
    var receiveAddress: String {
        "tb1q3ds30e5p59x9ryee4e2kxz9vxg5ur0tjsv0ug3"
    }
}
