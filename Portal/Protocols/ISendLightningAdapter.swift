//
//  ISendLightningAdapter.swift
//  Portal
//
//  Created by farid on 04.01.2024.
//

import Foundation

protocol ISendLightningAdapter: ILightningInvoiceHandler {
    var balance: Decimal { get }
    var spendable: Decimal { get }
}
