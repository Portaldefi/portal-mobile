//
//  BalanceAdapterMocked.swift
//  Portal
//
//  Created by farid on 9/29/22.
//

import Foundation
import Combine
import BitcoinDevKit

class BalanceAdapterMocked: IBalanceAdapter {
    var L1Balance: Decimal { 0.003 }    
    
    var state: AdapterState = .synced
    var balance: Decimal = 0.00055
    var balanceStateUpdated: AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
    var balanceUpdated: AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
}

class SendAssetMockedService: ISendAssetService {
    var balance: Decimal = 1.1
    var spendable: Decimal = 1.1
    var fee: Decimal = 0.0001
    var amount = CurrentValueSubject<Decimal, Never>(0.001)
    var feeRateType = CurrentValueSubject<TxFees, Never>(.normal)
    var receiverAddress: CurrentValueSubject<String, Never> = CurrentValueSubject<String, Never>("tb1q3ds30e5p59x9ryee4e2kxz9vxg5ur0tjsv0ug3")
    var feeRateProvider: IFeeRateProvider = MockeFeeRateProvider()
    var recomendedFees = CurrentValueSubject<RecomendedFees?, Never>(nil)
    
    init() {
        
    }
    
    func validateUserInput() throws -> UserInputResult {
        throw SendFlowError.addressIsntValid
    }
    
    func send() async throws -> TransactionRecord {
        TransactionRecord(transaction: TransactionDetails.mockedConfirmed, userData: TxUserData(price: 1000))
    }
    
    func sendMax() async throws -> TransactionRecord {
        try await send()
    }
}

class MockeFeeRateProvider: IFeeRateProvider {
    func recommendedFeeRate() async throws -> Int {
        10000
    }
}

class DepositAdapterMocked: IDepositAdapter {
    var receiveAddress: String {
        "tb1q3ds30e5p59x9ryee4e2kxz9vxg5ur0tjsv0ug3"
    }
}
