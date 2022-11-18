//
//  BalanceAdapterMocked.swift
//  Portal
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
    func sendMax(to: String, fee: Int?, completion: @escaping (String?, Error?) -> Void) {
        
    }
    
    func send(to: String, amount: String, fee: Int?, completion: @escaping (String?, Error?) -> Void) {
        
    }
}

class DepositAdapterMocked: IDepositAdapter {
    var receiveAddress: String {
        "tb1q3ds30e5p59x9ryee4e2kxz9vxg5ur0tjsv0ug3"
    }
}