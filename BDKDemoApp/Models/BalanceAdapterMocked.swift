//
//  BalanceAdapterMocked.swift
//  BDKDemoApp
//
//  Created by farid on 9/29/22.
//

import Foundation
import Combine

class BalanceAdapterMocked: IBalanceAdapter {
    var state: AdapterState = .synced
    var balance: Decimal = 0.00055
    var balanceStateUpdated: AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
    var balanceUpdated: AnyPublisher<Void, Never> {
        Just(()).eraseToAnyPublisher()
    }
}

class SendAdapterMocked: ISendAdapter {
    func send(to: String, amount: String, completion: @escaping (Error?) -> Void) {
        
    }
}
