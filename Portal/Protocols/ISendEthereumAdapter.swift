//
//  ISendEthereumAdapter.swift
//  Portal
//
//  Created by farid on 1/3/23.
//

import Foundation
import BigInt
import EvmKit
import Combine

protocol ISendEthereumAdapter {
    var balance: Decimal { get }
    func transactionData(amount: BigUInt, address: Address) -> TransactionData
    func send(tx: SendETHService.Transaction) -> Future<TransactionRecord, Error>
}
