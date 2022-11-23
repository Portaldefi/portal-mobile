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

class TransactionDetailsViewModel: ObservableObject {
    let storage: UserDefaults
    
    struct TestNetDataResponse: Codable {
        let height: Int
    }
    
    enum TxSide {
        case sent, received
    }
    
    let coin: Coin
    let transaction: TransactionDetails
    let blockChainHeight: Int32
    
    @Published var editingNotes = false
    @Published var editingLabels = false
    @Published var showAddLabelInterface = false
    @Published var newLabelTitle: String?
    
    @LazyInjected(Container.viewState) var viewState: ViewState
    
    var title: String {
        transaction.sent > 0 ? "Sent" : "Received"
    }
    
    var amountString: String {
        switch txSide {
        case .sent:
            return (Double(transaction.sent)/100_000_000).toString(decimal: 8)
        case .received:
            return (Double(transaction.received)/100_000_000).toString(decimal: 8)
        }
    }
    
    var currencyAmountString: String {
        "1.29"
    }
    
    var recipientString: String? {
        storage.object(forKey: transaction.txid + "recipient") as? String
    }
    
    var dateString: String {
        guard let blockTime = transaction.confirmationTime else {
            return Date().extendedDate()
        }
        
        return Date(timeIntervalSince1970: TimeInterval(blockTime.timestamp)).extendedDate()
    }
    
    var feeString: String {
        guard let fee = transaction.fee else { return "0.000000141" }
        return String(format: "%.8f", Double(fee)/100_000_000)
    }
        
    var txIdString: String {
        "\(transaction.txid.prefix(4))...\(transaction.txid.suffix(4))"
    }
    
    @Published var confirmations: Int32 = 0
    
    @Published var notes = String()
    @Published var labels: [TxLable] = []
    
    var explorerUrl: URL? {
        switch coin.type {
        case .bitcoin:
            return URL(string: "https://blockstream.info/testnet/tx/\(transaction.txid)")
        case .ethereum:
            return URL(string: "https://ropsten.etherscan.io/tx/\(transaction.txid)")
        default:
            return nil
        }
    }
    
    private var txSide: TxSide {
        transaction.sent > 0 ? .sent : .received
    }
        
    private var subscriptions = Set<AnyCancellable>()
    
    init(coin: Coin, tx: BitcoinDevKit.TransactionDetails, blockChainHeight: Int32) {
        self.coin = coin
        self.storage = UserDefaults.standard
        self.transaction = tx
        self.blockChainHeight = blockChainHeight
        
        if let notes = storage.string(forKey: transaction.txid + "notes") {
            self.notes = notes
        }
        
        if let tags = storage.object(forKey: transaction.txid + "labels") as? [String] {
            self.labels = tags.map{ TxLable(label: $0 )}
        }
        
        if let blockTime = tx.confirmationTime {
            confirmations = blockChainHeight - Int32(blockTime.height) + 1
        } else {
            confirmations = 0
        }
        
        $labels.sink { [unowned self] labels in
            self.storage.set(labels.map{ $0.label }, forKey: self.transaction.txid + "labels")
        }
        .store(in: &subscriptions)
        
        $notes.sink { [unowned self] notes in
            self.storage.set(notes, forKey: self.transaction.txid + "notes")
        }
        .store(in: &subscriptions)
    }
}

extension TransactionDetailsViewModel {
    static func config(coin: Coin, tx: BitcoinDevKit.TransactionDetails) -> TransactionDetailsViewModel {
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

