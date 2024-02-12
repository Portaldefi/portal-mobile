import Foundation

enum TxSource: Equatable {
    case bitcoin
    case ethereum
    case erc20(token: Erc20Token)
    case lightning
    case swap(base: Coin, quote: Coin)

    static func == (lhs: TxSource, rhs: TxSource) -> Bool {
        switch (lhs, rhs) {
        case (.bitcoin, .bitcoin), (.ethereum, .ethereum), (.lightning, .lightning):
            return true
        case let (.erc20(token1), .erc20(token2)):
            return token1.code == token2.code
        case let (.swap(base1, quote1), .swap(base2, quote2)):
            return base1 == base2 && quote1 == quote2
        default:
            return false
        }
    }
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
    
    func set(labels: [TxLabel]) {
        userData.labels = labels
    }
    
    func set(notes: String?) {
        userData.notes = notes
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
