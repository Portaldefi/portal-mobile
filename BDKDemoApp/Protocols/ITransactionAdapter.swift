//
//  ITransactionAdapter.swift
//  Portal
//
//  Created by Farid on 13.07.2021.
//

import Foundation
import Combine
import BitcoinDevKit

protocol ITransactionsAdapter {
    var transactionRecords: AnyPublisher<[BitcoinDevKit.TransactionDetails], Never> { get }
}
