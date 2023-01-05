//
//  SendBTCService.swift
//  Portal
//
//  Created by farid on 1/4/23.
//

import Foundation
import Combine

class SendBTCService: ISendAssetService {
    private let sendAdapter: ISendBitcoinAdapter
    private let balanceAdapter: IBalanceAdapter
    
    private(set) var feeRateProvider: IFeeRateProvider
    
    var amount = CurrentValueSubject<Decimal, Never>(0)
    var feeRate = CurrentValueSubject<Int, Never>(1)
    var receiverAddress = CurrentValueSubject<String, Never>(String())
    
    var balance: Decimal {
        balanceAdapter.balance
    }
    
    var spendable: Decimal {
        sendAdapter.availableBalance(feeRate: feeRate.value, address: receiverAddress.value)
    }
    
    var fee: Decimal {
        sendAdapter.fee(amount: amount.value > 0 ? amount.value : 0.0001, feeRate: feeRate.value, address: receiverAddress.value)
    }

    init(balanceAdapter: IBalanceAdapter, sendAdapter: ISendBitcoinAdapter, feeRateProvider: IFeeRateProvider) {
        self.sendAdapter = sendAdapter
        self.balanceAdapter = balanceAdapter
        self.feeRateProvider = feeRateProvider
    }
    
    func validateAddress() throws {
        try sendAdapter.validate(address: receiverAddress.value)
    }
    
    func send() -> Future<Void, Error> {
        sendAdapter.send(amount: amount.value, address: receiverAddress.value, feeRate: feeRate.value)
    }
}
