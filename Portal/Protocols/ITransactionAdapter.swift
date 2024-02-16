//
//  ITransactionAdapter.swift
//  Portal
//
//  Created by Farid on 13.07.2021.
//

import Foundation
import Combine

protocol ITransactionsAdapter {
    var lastKnownTxTimestamp: Int { get }
    var transactionRecords: [TransactionRecord] { get }
    var onTxsUpdate: AnyPublisher<Void, Never> { get }
}
