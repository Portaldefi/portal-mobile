//
//  LightningPayment.swift
//  Portal
//
//  Created by farid on 6/6/22.
//

import Foundation
import LightningDevKit

class LightningPayment: Identifiable {
    
    static let samplePayment = LightningPayment(
        id: UUID().uuidString,
        satAmount: 20000,
        created: Date(),
        description: "Test payment",
        state: .sent
    )
    
    enum State: Int16 {
        case requested = 0, sent, received
        
        var description: String {
            switch self {
            case .requested:
                return "Requested payment"
            case .sent:
                return "Sent"
            case .received:
                return "Received"
            }
        }
    }
    
    let id: String
    let satAmount: UInt64
    let created: Date
    let expires: Date?
    let description: String
    var state: State
    var invoice: String?
    
    var isExpired: Bool {
        guard let expireDate = expires else {
            return false
        }
        return Date() > expireDate
    }
    
    init(invoice: Invoice, memo: String) {
        self.id = UUID().uuidString
        self.satAmount = invoice.amountMilliSatoshis()!/1000
        self.created = Date()
        let expiteTime = TimeInterval(invoice.expiryTime())
        self.expires = Date(timeInterval: expiteTime, since: created)
        self.state = .requested
        self.invoice = invoice.toStr()
        self.description = memo//invoice.into_signed_raw().raw_invoice().description().into_inner()
    }
    
    init(id: String, satAmount: Int64, created: Date, description: String, state: State) {
        self.id = id
        self.satAmount = UInt64(satAmount)
        self.created = created
        self.description = description
        self.state = state
        self.expires = nil
    }
    
//    init(record: DBLightningPayment) {
//        self.id = record.paymentID
//        self.satAmount = UInt64(record.satValue)
//        self.created = record.created
//        self.expires = record.expires
//        self.description = record.memo
//        self.state = State(rawValue: record.state)!
//        self.invoice = record.invoice
//    }
}
