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
    var receiver: CurrentValueSubject<String, Never> { get }
    var feeRateType: CurrentValueSubject<TxFees, Never> { get }
    var recomendedFees: CurrentValueSubject<RecomendedFees?, Never> { get }
    
    func validateUserInput() throws -> UserInputResult
    func send() async throws -> TransactionRecord
    func sendMax() async throws -> TransactionRecord
}
