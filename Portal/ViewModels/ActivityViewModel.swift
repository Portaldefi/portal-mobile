//
//  ActivityViewModel.swift
//  Portal
//
//  Created by farid on 29.06.2023.
//

import Foundation
import Factory
import Combine
import PortalSwapSDK
import SwiftUI

enum SortOptions {
    case date, amount, coin
}

enum TxFilterOption {
    case none, sent, received, swap, success, pending, failed
}

class ActivityViewModel: ObservableObject {
    private let adapterManager: IAdapterManager
    private let walletManager: IWalletManager
    private let txDataStorage: ITxUserDataStorage
    
    private var transactions = [TransactionRecord]()
    private var persistenceManager: LocalPersistenceManager?
    private var subscriptions = Set<AnyCancellable>()
    
    @Published private(set) var searchResults = [TransactionRecord]()

    @Published var selectedTx: TransactionRecord?
    @Published var filteredTransactions = [TransactionRecord]()
    @Published var txTypeFilter: TxFilterOption = .none
    @Published var selectedSort: SortOptions = .date
    @Published var isDescending: Bool = false
    @Published var searchContext = String()
    
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
    
    private var swapContractAddress: String {
        let config = Container.configProvider()
        
        switch config.network {
        case .playnet:
            return "0x61F69Ead9cF1380C310b482C6626B2cFAeD03353".lowercased()
        case .testnet:
            return "0x5c3B565127e4E4e6756710411E4108BC788e9516".lowercased()
        case .mainnet:
            fatalError("Not impemented")
        }
    }
                    
    private init(adapterManager: IAdapterManager, walletManager: IWalletManager, txDataStorage: ITxUserDataStorage) {
        self.adapterManager = adapterManager
        self.walletManager = walletManager
        self.txDataStorage = txDataStorage
        
        persistenceManager = try? LocalPersistenceManager.manager()

        subscribeForSearchContext()
    }
        
    func updateTransactions() {
        transactions.removeAll()
        
        var swapRecords = [SwapTransactionRecord]()
        
        if let manager = persistenceManager {
            if let swaps = try? manager.fetchSwaps().filter({ $0.status == "completed" }) {
                for swap in swaps {
                    let source: TxSource = .swap(base: .lightningBitcoin(), quote: .ethereum())
                    let data = txDataStorage.fetch(source: source, id: swap.swapId)
                    let userData = TxUserData(data: data)
                    let swapRecord = SwapTransactionRecord(swap: swap, userData: userData)
                    
                    swapRecords.append(swapRecord)
                }
            }
        }
        
        let swapsIds = swapRecords.map{ $0.id }
        
        transactions = walletManager.activeWallets
            .compactMap { adapterManager.transactionsAdapter(for: $0) }
            .flatMap { $0.transactionRecords }
            .filter { transaction in
                switch transaction {
                case let record as EvmTransactionRecord:
                    guard record.receiver == swapContractAddress else { return true }
                    return false
                case let record as LNTransactionRecord:
                    guard swapsIds.contains(record.memo ?? String()) else { return true }
                    return false
                default:
                    return true
                }
            }
            + swapRecords
        
        applyFilterAndSort()
    }
    
    private func subscribeForSearchContext() {
        $searchContext.sink { [unowned self] context in
            guard !context.isEmpty else { return }
            let searchContext = context.lowercased()
            self.searchResults = transactions.filter {
                switch $0 {
                case let record as BTCTransactionRecord:
                    return record.coin.name.lowercased().contains(searchContext) ||
                    record.coin.code.lowercased().contains(searchContext) ||
                    String(describing: record.amount ?? 0).lowercased().contains(searchContext) ||
                    record.notes?.lowercased().contains(searchContext) ?? false ||
                    !record.labels.filter{ $0.label.contains(searchContext) }.isEmpty ||
                    record.type.description.lowercased().contains(searchContext)
                case let record as EvmTransactionRecord:
                    return record.coin.name.lowercased().contains(searchContext) ||
                    record.coin.code.lowercased().contains(searchContext) ||
                    String(describing: record.amount ?? 0).lowercased().contains(searchContext) ||
                    record.notes?.lowercased().contains(searchContext) ?? false ||
                    !record.labels.filter{ $0.label.contains(searchContext) }.isEmpty ||
                    record.type.description.lowercased().contains(searchContext)
                case let record as LNTransactionRecord:
                    return Coin.lightningBitcoin().name.lowercased().contains(searchContext) ||
                    Coin.lightningBitcoin().code.lowercased().contains(searchContext) ||
                    String(describing: record.amount ?? 0).lowercased().contains(searchContext) ||
                    record.notes?.lowercased().contains(searchContext) ?? false ||
                    !record.labels.filter{ $0.label.contains(searchContext) }.isEmpty ||
                    record.type.description.lowercased().contains(searchContext)
                case let record as SwapTransactionRecord:
                    return record.base.name.lowercased().contains(searchContext) ||
                    record.quote.code.lowercased().contains(searchContext) ||
                    record.quote.name.lowercased().contains(searchContext) ||
                    record.quote.code.lowercased().contains(searchContext) ||
                    String(describing: record.baseQuantity).lowercased().contains(searchContext) ||
                    String(describing: record.quoteQuantity).lowercased().contains(searchContext) ||
                    record.notes?.lowercased().contains(searchContext) ?? false ||
                    !record.labels.filter{ $0.label.contains(searchContext) }.isEmpty ||
                    record.type.description.lowercased().contains(searchContext)
                default:
                    return false
                }
            }
        }
        .store(in: &subscriptions)
    }
    
    func updateTxTypeFilter(filter: TxFilterOption) {
        self.txTypeFilter = filter
        self.applyFilterAndSort()
    }
        
    func updateSort(sort: SortOptions) {
        self.selectedSort = sort
        self.applyFilterAndSort()
    }
    
    func toggleSortOrder() {
        self.isDescending = !self.isDescending
        self.applyFilterAndSort()
    }
    
    private func applyFilterAndSort() {
        var newTransactions = transactions
        
        switch txTypeFilter {
        case .none:
            break
        case .sent:
            newTransactions = newTransactions.filter { $0.type.description.contains("Sent") }
        case .received:
            newTransactions = newTransactions.filter { $0.type.description.contains("Received") }
        case .swap:
            newTransactions = newTransactions.filter { $0.type.description.contains(" to ") }
        case .success:
            newTransactions = newTransactions.filter { $0.confirmationTimeString != nil }
        case .pending:
            newTransactions = newTransactions.filter { $0.confirmationTimeString == nil }
        case .failed:
            newTransactions = []
        }
        
        newTransactions.sort { record1, record2 in
            switch selectedSort {
            case .date:
                // Make sure that timestamp is not nil and insert unconfirmed transactions on top
                let date1 = record1.timestamp != nil ? Date(timeIntervalSince1970: TimeInterval(record1.timestamp!)) : isDescending ? Date.distantPast : Date.now
                let date2 = record2.timestamp != nil ? Date(timeIntervalSince1970: TimeInterval(record2.timestamp!)) : isDescending ? Date.distantPast : Date.now
                return isDescending ? (date1 < date2) : (date1 > date2)
            case .amount:
                // Make sure that amount is not nil
                
                let amount1: Decimal
                
                switch record1 {
                case let record as BTCTransactionRecord:
                    amount1 = record.amount ?? 0
                case let record as EvmTransactionRecord:
                    amount1 = record.amount ?? 0
                case let record as LNTransactionRecord:
                    amount1 = record.amount ?? 0
                case let record as SwapTransactionRecord:
                    amount1 = record.baseQuantity
                default:
                    amount1 = 0
                }
                
                let amount2: Decimal
                
                switch record2 {
                case let record as BTCTransactionRecord:
                    amount2 = record.amount ?? 0
                case let record as EvmTransactionRecord:
                    amount2 = record.amount ?? 0
                case let record as LNTransactionRecord:
                    amount2 = record.amount ?? 0
                case let record as SwapTransactionRecord:
                    amount2 = record.baseQuantity
                default:
                    amount2 = 0
                }
        
                return isDescending ? (amount1 < amount2) : (amount1 > amount2)
            case .coin:
                switch (record1.type, record2.type) {
                    case (.sent(let coin1), .sent(let coin2)):
                        return !isDescending ? (coin1.code < coin2.code) : (coin1.code > coin2.code)
                    case (.received(let coin1), .received(let coin2)):
                        return !isDescending ? (coin1.code < coin2.code) : (coin1.code > coin2.code)
                    case (.swap(let base1, _), .swap(let base2, _)):
                        return !isDescending ? (base1.code < base2.code) : (base1.code > base2.code)
                    default:
                        return false
                    }
            }
        }
        
        self.filteredTransactions = newTransactions
    }
}

extension ActivityViewModel {
    static func config() -> ActivityViewModel {
        ActivityViewModel(
            adapterManager: Container.adapterManager(),
            walletManager: Container.walletManager(), 
            txDataStorage: Container.txDataStorage()
        )
    }
}

