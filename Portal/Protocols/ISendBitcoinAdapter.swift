//
//  ISendBitcoinAdapter.swift
//  Portal
//
//  Created by farid on 1/5/23.
//

import Foundation
import Combine

protocol ISendBitcoinAdapter {
    var balance: Decimal { get }
    func availableBalance(feeRate: Int, address: String?) -> Decimal
    func minimumSendAmount(address: String?) -> Decimal
    func validate(address: String) throws
    func fee(amount: Decimal, feeRate: Int, address: String?) -> Decimal
    func send(amount: Decimal, address: String, feeRate: Int) -> Future<Void, Error>
}
