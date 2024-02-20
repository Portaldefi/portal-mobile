//
//  ISendLightningAdapter.swift
//  Portal
//
//  Created by farid on 04.01.2024.
//

import Foundation
import LightningDevKit

protocol ISendLightningAdapter {
    var balance: Decimal { get }
    var spendable: Decimal { get }
    func decode(invoice: String) throws -> Bolt11Invoice
    func pay(invoice: String) async throws -> TransactionRecord
}
