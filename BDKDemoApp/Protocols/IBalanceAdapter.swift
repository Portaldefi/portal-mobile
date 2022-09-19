//
//  IBalanceAdapter.swift
//  Portal
//
//  Created by Farid on 13.07.2021.
//

import Foundation
import Combine

protocol IBalanceAdapter {
    var balanceState: AdapterState { get }
    var balance: Decimal { get }
    var balanceLocked: Decimal? { get }
    var balanceStateUpdated: AnyPublisher<Void, Never> { get }
    var balanceUpdated: AnyPublisher<Void, Never> { get }
}

extension IBalanceAdapter {
    var balanceLocked: Decimal? { nil }
}
