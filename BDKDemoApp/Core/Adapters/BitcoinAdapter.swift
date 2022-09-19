//
//  BitcoinAdapter.swift
//  BDKDemoApp
//
//  Created by farid on 9/19/22.
//

import Foundation
import Combine
import BitcoinDevKit

final class BitcoinAdapter {
    private let stateUpdatedSubject = PassthroughSubject<Void, Never>()
    private let balanceUpdatedSubject = PassthroughSubject<Void, Never>()
}

extension BitcoinAdapter: IBalanceAdapter {
    var balanceState: AdapterState {
        .syncing(progress: 0, lastBlockDate: nil)
    }
    
    var balance: Decimal {
        0
    }
    
    var balanceStateUpdated: AnyPublisher<Void, Never> {
        stateUpdatedSubject.eraseToAnyPublisher()
    }
    
    var balanceUpdated: AnyPublisher<Void, Never> {
        balanceUpdatedSubject.eraseToAnyPublisher()
    }
}

extension BitcoinAdapter: IDepositAdapter {
    var receiveAddress: String {
        String()
    }
}

extension BitcoinAdapter: ITransactionsAdapter {
    var coin: Coin {
        .bitcoin()
    }
    
    var transactionRecords: AnyPublisher<[Transaction], Never> {
        Just([Transaction]()).eraseToAnyPublisher()
    }
    
    func transactions(from: Transaction?, limit: Int) -> Future<[Transaction], Never> {
        Future { promise in
            promise(.success([]))
        }
    }
}

