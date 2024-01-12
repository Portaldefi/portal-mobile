import Foundation

enum TxSource: Equatable {
    case btcOnChain, ethOnChain, lightning, swap(base: Coin, quote: Coin)
}

class TransactionRecord: Identifiable {
    let id: String
    let source: TxSource
    let type: TxType
    let timestamp: Int?
    
    private let userData: TxUserData
        
    var confirmationTimeString: String? {
        guard let confirmationTime = self.timestamp else { return nil }
        let date = Date(timeIntervalSince1970: TimeInterval(confirmationTime))
        return date.formatted()
    }
    
    var notes: String?  {
        userData.notes
    }
    
    var labels: [TxLabel] {
        userData.labels
    }
    
    var price: Decimal {
        userData.price
    }
    
    init(source: TxSource, type: TxType, id: String, timestamp: Int?, userData: TxUserData) {
        self.source = source
        self.type = type
        self.id = id
        self.timestamp = timestamp
        self.userData = userData
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
