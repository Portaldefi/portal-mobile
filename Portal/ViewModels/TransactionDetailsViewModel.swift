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
    struct TestNetDataResponse: Codable {
        let height: Int
    }
    
    let coin: Coin
    let transaction: TransactionRecord
    
    private let storage: ITxUserDataStorage
    
    @Published var blockChainHeight: Int32 = 0
    
    @Published var editingNotes = false
    @Published var editingLabels = false
    @Published var showAddLabelInterface = false
    @Published var newLabelTitle: String?
    @Published var source: TxSource = .btcOnChain
    
    @Injected(Container.settings) private var settings

    var fiatCurrency: FiatCurrency {
        settings.fiatCurrency.value
    }
        
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
        let txAmount: Decimal?
        
        switch transaction {
        case let record as BTCTransactionRecord:
            switch transaction.type {
            case .sent:
                if let amount = record.amount, let fee = record.fee {
                    txAmount = amount - (fee*100_000_000)
                } else {
                    txAmount = record.amount
                }
            default:
                txAmount = record.amount
            }
        case let record as EvmTransactionRecord:
            txAmount = record.amount
        case let record as LNTransactionRecord:
            txAmount = record.amount
        case let record as SwapTransactionRecord:
            txAmount = record.baseQuantity
        default:
            txAmount = nil
        }
        
        guard let amount = txAmount else { return "0" }
        
        switch coin.type {
        case .bitcoin, .lightningBitcoin:
            return Double(amount.double/100_000_000).toString(decimal: 8)
        case .ethereum:
            return amount.double.toString(decimal: 8)
        case .erc20:
            return amount.double.toString(decimal: 8)
        }
    }
    
    var currencyAmountString: String {
        let txAmount: Decimal?
        
        switch transaction {
        case let record as BTCTransactionRecord:
            txAmount = record.amount
        case let record as EvmTransactionRecord:
            txAmount = record.amount
        case let record as LNTransactionRecord:
            txAmount = record.amount
        case let record as SwapTransactionRecord:
            txAmount = record.baseQuantity
        default:
            txAmount = nil
        }
        
        guard let amount = txAmount else { return "0" }
        
        switch coin.type {
        case .bitcoin, .lightningBitcoin:
            return (transaction.price * (amount/100_000_000) * fiatCurrency.rate).double.formattedString(.fiat(fiatCurrency))
        case .ethereum, .erc20:
            return (transaction.price * amount * fiatCurrency.rate).double.formattedString(.fiat(fiatCurrency))
        }
    }
    
    var recipientString: String? {
        switch transaction {
        case let record as BTCTransactionRecord:
            return record.receiver
        case let record as EvmTransactionRecord:
            return record.receiver
        case let record as LNTransactionRecord:
            return record.receiver
        default:
            return nil
        }
    }
    
    var senderString: String? {
        switch transaction {
        case let record as BTCTransactionRecord:
            return record.sender
        case let record as EvmTransactionRecord:
            return record.sender
        case let record as LNTransactionRecord:
            return record.sender
        default:
            return nil
        }
    }
    
    var dateString: String {
        guard let timestamp = transaction.timestamp else {
            return Date().extendedDate()
        }
        
        return Date(timeIntervalSince1970: TimeInterval(timestamp)).extendedDate()
    }
    
    var feeString: String {
        let fee: Decimal?
        
        switch transaction {
        case let record as BTCTransactionRecord:
            fee = record.fee
        case let record as EvmTransactionRecord:
            fee = record.fee
        case let record as LNTransactionRecord:
            fee = record.fee
        default:
            fee = nil
        }
        guard let txFee = fee else { return "-" }
        return String(describing: txFee)
    }
        
    var txIdString: String {
        "\(transaction.id.prefix(4))...\(transaction.id.suffix(4))"
    }
    
    @Published var confirmations: Int32 = 0
    
    @Published var notes = String()
    @Published var labels: [TxLabel] = []
    
    var explorerUrl: URL? {
        switch coin.type {
        case .bitcoin:
            return URL(string: "https://blockstream.info/testnet/tx/\(transaction.id)")
        case .ethereum:
            return URL(string: "https://sepolia.etherscan.io/tx/\(transaction.id)")
        default:
            return nil
        }
    }
    
    private var subscriptions = Set<AnyCancellable>()
    
    init(coin: Coin, tx: TransactionRecord, blockChainHeight: Int32) {
        self.storage = Container.txDataStorage()

        self.coin = coin
        self.transaction = tx
        self.blockChainHeight = blockChainHeight
        self.source = transaction.source
        
        switch tx {
        case let record as BTCTransactionRecord:
            if let blockHeight = record.blockHeight {
                confirmations = blockChainHeight - Int32(blockHeight) + 1
            }
        case let record as EvmTransactionRecord:
            if let blockHeight = record.blockHeight {
                confirmations = blockChainHeight - Int32(blockHeight) + 1
            }
        default:
            break
        }
                
        if let notes = tx.notes, !notes.isEmpty {
            self.notes = notes
        }
        
        self.labels = tx.labels
        
        $labels.removeDuplicates().dropFirst().sink { [unowned self] labels in
            self.storage.update(source: tx.source, id: tx.id, labels: labels)
        }
        .store(in: &subscriptions)
        
        $notes.removeDuplicates().dropFirst().sink { [unowned self] notes in
            self.storage.update(source: tx.source, id: tx.id, notes: notes)
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

