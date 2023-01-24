//
//  TransactionDetailsViewModel.swift
// Portal
//
//  Created by farid on 10/2/22.
//

import Foundation
import Combine
import BitcoinDevKit
import Factory
import BigInt

class TransactionDetailsViewModel: ObservableObject {
    let storage: UserDefaults
    
    struct TestNetDataResponse: Codable {
        let height: Int
    }
    
    let coin: Coin
    let transaction: TransactionRecord
    let blockChainHeight: Int32
    
    @Published var editingNotes = false
    @Published var editingLabels = false
    @Published var showAddLabelInterface = false
    @Published var newLabelTitle: String?
    
    @LazyInjected(Container.viewState) var viewState: ViewState
    
    var title: String {
        transaction.type.description
    }
    
    private func convertAmount(amount: BigUInt, decimals: Int, sign: FloatingPointSign) -> Decimal {
        guard let significand = Decimal(string: amount.description), significand != 0 else {
            return 0
        }

        return Decimal(sign: sign, exponent: -decimals, significand: significand)
    }
    
    var amountString: String {
        guard let amount = transaction.amount else { return "0" }
        switch coin.type {
        case .bitcoin:
            return Double(amount.double/100_000_000).toString(decimal: 8)
        case .ethereum:
            return amount.double.toString(decimal: 8)
        default:
            return "0"
        }
    }
    
    var currencyAmountString: String {
        "1.29"
    }
    
    var recipientString: String? {
        storage.object(forKey: transaction.id + "recipient") as? String
    }
    
    var dateString: String {
        guard let timestamp = transaction.timestamp else {
            return Date().extendedDate()
        }
        
        return Date(timeIntervalSince1970: TimeInterval(timestamp)).extendedDate()
    }
    
    var feeString: String {
        guard let fee = transaction.fee else { return "-" }
        return String(describing: fee)
    }
        
    var txIdString: String {
        "\(transaction.id.prefix(4))...\(transaction.id.suffix(4))"
    }
    
    @Published var confirmations: Int32 = 0
    
    @Published var notes = String()
    @Published var labels: [TxLable] = []
    
    var explorerUrl: URL? {
        switch coin.type {
        case .bitcoin:
            return URL(string: "https://blockstream.info/testnet/tx/\(transaction.id)")
        case .ethereum:
            return URL(string: "https://goerli.etherscan.io/tx/\(transaction.id)")
        default:
            return nil
        }
    }
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(coin: Coin, tx: TransactionRecord, blockChainHeight: Int32) {
        self.coin = coin
        self.storage = UserDefaults.standard
        self.transaction = tx
        self.blockChainHeight = blockChainHeight
        
        if let notes = storage.string(forKey: transaction.id + "notes") {
            self.notes = notes
        }
        
        if let tags = storage.object(forKey: transaction.id + "labels") as? [String] {
            self.labels = tags.map{ TxLable(label: $0 )}
        }
        
        if let blockHeight = tx.blockHeight {
            confirmations = blockChainHeight - Int32(blockHeight) + 1
        }
        
        $labels.sink { [unowned self] labels in
            self.storage.set(labels.map{ $0.label }, forKey: self.transaction.id + "labels")
        }
        .store(in: &subscriptions)
        
        $notes.sink { [unowned self] notes in
            self.storage.set(notes, forKey: self.transaction.id + "notes")
        }
        .store(in: &subscriptions)
    }
}

extension TransactionDetailsViewModel {
    static func config(coin: Coin, tx: TransactionRecord) -> TransactionDetailsViewModel {
        let adapterManager: IAdapterManager = Container.adapterManager()
        let walletManager: IWalletManager = Container.walletManager()
                
        guard
            let wallet = walletManager.activeWallets.first(where: { $0.coin == coin }),
            let adapter = adapterManager.adapter(for: wallet)
        else {
            fatalError("coudn't fetch dependencies")
        }
        
        return TransactionDetailsViewModel(coin: coin, tx: tx, blockChainHeight: adapter.blockchainHeight)
    }
}

