//
//  SendLightningService.swift
//  Portal
//
//  Created by farid on 04.01.2024.
//

import Foundation
import Combine

class SendLightningService: ISendAssetService {
    private let adapter: ISendLightningAdapter
    
    init(adapter: ISendLightningAdapter) {
        self.adapter = adapter
    }
    
    var balance: Decimal {
        adapter.balance
    }
    
    var spendable: Decimal {
        adapter.spendable
    }
    
    var fee: Decimal = 0
    
    var amount = CurrentValueSubject<Decimal, Never>(0)
    var receiver = CurrentValueSubject<String, Never>(String())
    var feeRateType = CurrentValueSubject<TxFees, Never>(.normal)
    var recomendedFees = CurrentValueSubject<RecomendedFees?, Never>(nil)
    
    func validateUserInput() throws -> UserInputResult {
        let inputString = receiver.value
        
        let invoice = try adapter.decode(invoice: inputString)
        
        if let value = invoice.amountMilliSatoshis() {
            return .lightningInvoice(amount: String(describing: Decimal(value)/1000/100_000_000))
        } else {
            return .lightningInvoice(amount: String())
        }
    }
    
    func send() async throws -> TransactionRecord {
        try await adapter.pay(invoice: receiver.value)
    }
    
    func sendMax() async throws -> TransactionRecord {
        fatalError("Not impemented")
    }
}
