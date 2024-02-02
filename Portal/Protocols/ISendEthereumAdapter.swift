//
//  ISendEthereumAdapter.swift
//  Portal
//
//  Created by farid on 1/3/23.
//

import Foundation
import BigInt
import EvmKit

protocol ISendEthereumAdapter {
    var balance: Decimal { get }
    func transactionData(amount: BigUInt, address: Address) -> TransactionData
    func send(transaction: SendETHService.Transaction) async throws -> TransactionRecord
    func callSolidity(contractAddress: Address, data: Data) async throws -> Data
    func transactionReceipt(hash: Data) async throws -> RpcTransactionReceipt
    func send(transactionData: TransactionData, gasLimit: Int, gasPrice: GasPrice) async throws -> FullTransaction
}
