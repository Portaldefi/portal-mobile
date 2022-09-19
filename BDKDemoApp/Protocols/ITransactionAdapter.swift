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
    var coin: Coin { get }
    var transactionRecords: AnyPublisher<[BitcoinDevKit.Transaction], Never> { get }
    func transactions(from: BitcoinDevKit.Transaction?, limit: Int) -> Future<[BitcoinDevKit.Transaction], Never>
}
