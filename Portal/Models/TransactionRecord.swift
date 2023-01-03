import Foundation
import BitcoinDevKit
import EvmKit

struct TransactionRecord: Identifiable {
    let id: String
    let type: TxType
    let timestamp: Int?
    let blockHeight: Int?
    let from: String?
    let to: String?
    let amount: Decimal?
    
    var confirmationTimeString: String? {
        guard let confirmationTime = self.timestamp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(confirmationTime)).formatted()
    }
    
    var notes: String?  {
        UserDefaults.standard.string(forKey: self.id + "notes")
    }
    
    var labels: [TxLable] {
        guard let tags = UserDefaults.standard.object(forKey: self.id + "labels") as? [String] else {
            return []
        }
        return tags.map{ TxLable(label: $0 )}
    }
    
    init(transaction: BitcoinDevKit.TransactionDetails) {
        self.id = transaction.txid
        self.type = transaction.sent > 0 ? .sent : .received
        
        switch self.type {
        case .sent:
            self.amount = Decimal(transaction.sent)
        case .received:
            self.amount = Decimal(transaction.received)
        case .swapped:
            self.amount = nil
        }
        
        if let blockInfo = transaction.confirmationTime {
            self.timestamp = Int(blockInfo.timestamp)
            self.blockHeight = Int(blockInfo.height)
        } else {
            self.timestamp = nil
            self.blockHeight = nil
        }
        
        self.from = nil
        self.to = nil
    }
    
    init(transaction: EvmKit.Transaction, amount: Decimal?, type: TxType) {
        self.id = transaction.hash.hs.hexString
        self.type = type
        self.amount = amount
        self.to = transaction.to?.hex
        self.from = transaction.from?.hex
        self.timestamp = transaction.timestamp
        self.blockHeight = transaction.blockNumber
    }
}

extension TransactionRecord: Hashable {
    public static func ==(lhs: TransactionRecord, rhs: TransactionRecord) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension TransactionRecord {
    static var mocked: TransactionRecord {
        TransactionRecord(transaction: TransactionDetails.mockedConfirmed)
    }
}
