//
//  BitcoinDevKitTransaction+Extension.swift
//  Portal
//
//  Created by farid on 10/3/22.
//

import BitcoinDevKit
import Foundation

enum TxType: Equatable {
    case sent, received, swapped(for: Coin)
    
    var description: String {
        switch self {
        case .sent:
            return "Sent"
        case .received:
            return "Received"
        case .swapped(for: let coin):
            return "Swapped for \(coin.code)"
        }
    }
}

extension BitcoinDevKit.TransactionDetails: Equatable {
    public static func == (lhs: BitcoinDevKit.TransactionDetails, rhs: BitcoinDevKit.TransactionDetails) -> Bool {
        lhs.txid == rhs.txid
    }
    
    static var mockedConfirmed: BitcoinDevKit.TransactionDetails {
        let blockTime = BlockTime(height: 2345912, timestamp: 1662707961)
        return TransactionDetails(
            transaction: nil,
            fee: 141,
            received: 55000,
            sent: 0,
            txid: "088719f8db335b69c1e1a57b06d6925c941e99bf55607394e0902283a70fd44e",
            confirmationTime: blockTime
        )
    }
    
    static func unconfirmedSentTransaction(recipient: String, amount: String, id: String) -> BitcoinDevKit.TransactionDetails {
        let satAmountDouble = (Double(amount) ?? 0) * 100_000_000
        let satAmountInt = UInt64(satAmountDouble)
        let defaults = UserDefaults.standard
        defaults.set("\(recipient.prefix(4))...\(recipient.suffix(4))", forKey: id + "recipient")
        return TransactionDetails(transaction: nil, fee: nil, received: 0, sent: satAmountInt, txid: id, confirmationTime: nil)
    }
    
    var type: TxType {
        if self.sent > 0 {
            return .sent
        } else {
            return .received
        }
    }
    
    var confirmationTimeString: String? {
        guard let confirmationTime = self.confirmationTime else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(confirmationTime.timestamp)).formatted()
    }
    
    var notes: String?  {
        UserDefaults.standard.string(forKey: self.txid + "notes")
    }
    
    var labels: [TxLable] {
        guard let tags = UserDefaults.standard.object(forKey: self.txid + "labels") as? [String] else {
            return []
        }
        return tags.map{ TxLable(label: $0 )}
    }
    
    var value: String {
        self.sent > 0 ? "\(Double(self.sent)/100_000_000)" : "\(Double(self.received)/100_000_000)"
    }
}
