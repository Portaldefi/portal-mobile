//
//  ISendAssetService.swift
//  Portal
//
//  Created by farid on 1/3/23.
//

import Foundation
import Combine

protocol ISendAssetService {
    var balance: Decimal { get }
    var spendable: Decimal { get }
    var fee: Decimal { get }
    var amount: CurrentValueSubject<Decimal, Never> { get }
    var receiverAddress: CurrentValueSubject<String, Never> { get }
    var feeRateType: CurrentValueSubject<TxFees, Never> { get }
    var recomendedFees: CurrentValueSubject<RecomendedFees?, Never> { get }
    
    func validateAddress() throws
    func send() -> Future<TransactionRecord, Error>
    func sendMax() -> Future<TransactionRecord, Error>
}
