//
//  ISendBitcoinAdapter.swift
//  Portal
//
//  Created by farid on 1/5/23.
//

import Foundation
import BitcoinDevKit

protocol ISendBitcoinAdapter {
    var balance: Decimal { get }
    func validate(address: String) throws
    func fee(max: Bool, address: String, amount: Decimal, fee: Int?) throws -> UInt64?
    func send(amount: Decimal, address: String, fee: Int?) throws -> TransactionRecord
    func rawTransaction(amount: UInt64, address: String) throws -> Transaction
    func sendMax(address: String, fee: Int?) throws -> TransactionRecord
    func send(amount: Decimal, address: String) throws -> TransactionRecord
}
