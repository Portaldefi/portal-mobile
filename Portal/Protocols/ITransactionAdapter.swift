//
//  ITransactionAdapter.swift
//  Portal
//
//  Created by Farid on 13.07.2021.
//

import Foundation
import Combine

protocol ITransactionsAdapter {
    var transactionRecords: AnyPublisher<[TransactionRecord], Never> { get }
}
