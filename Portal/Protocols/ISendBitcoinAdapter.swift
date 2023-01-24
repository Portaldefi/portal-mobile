//
//  ISendBitcoinAdapter.swift
//  Portal
//
//  Created by farid on 1/5/23.
//

import Foundation
import Combine

protocol ISendBitcoinAdapter {
    var balance: Decimal { get }
    func validate(address: String) throws
    func fee(max: Bool, address: String, amount: Decimal, fee: Int?) throws -> UInt64?
    func send(amount: Decimal, address: String, fee: Int?) -> Future<TransactionRecord, Error>
    func sendMax(address: String, fee: Int?) -> Future<TransactionRecord, Error>
}
