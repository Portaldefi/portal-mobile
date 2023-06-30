//
//  ActivityViewModel.swift
//  Portal
//
//  Created by farid on 29.06.2023.
//

import Foundation
import Factory
import Combine

enum SortOptions {
    case date, amount, coin
}

enum TxFilterOption {
    case none, send, received, swapped, success, pending, failed
}

class ActivityViewModel: ObservableObject {
    @Published var selectedTx: TransactionRecord?
    @Published private(set) var searchResults = [TransactionRecord]()
    @Published var filteredTransactions = [TransactionRecord]()
    @Published var txTypeFilter: TxFilterOption = .none
    @Published var selectedSort: SortOptions = .date
    @Published var isDescending: Bool = false
    
    private var transactions = [TransactionRecord]()
        
    @Published var searchContext = String()
    @Injected(Container.viewState) var viewState
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        updateTransactions()
        
        $searchContext.sink { [unowned self] context in
            guard !context.isEmpty else { return }
            let searchContext = context.lowercased()
            self.searchResults = transactions.filter {
                $0.coin.name.lowercased().contains(searchContext) ||
                $0.coin.code.lowercased().contains(searchContext) ||
                String(describing: $0.amount ?? 0).lowercased().contains(searchContext) ||
                $0.notes?.lowercased().contains(searchContext) ?? false ||
                !$0.labels.filter{ $0.label.contains(searchContext) }.isEmpty ||
                $0.type.description.lowercased().contains(searchContext)
            }
        }
        .store(in: &subscriptions)
    }
    
    func updateTransactions() {
        subscriptions.removeAll()
        transactions.removeAll()
        
        let adapterManager: IAdapterManager = Container.adapterManager()
        let walletManager: IWalletManager = Container.walletManager()
        
        Publishers.MergeMany(
            walletManager.activeWallets
                .compactMap { adapterManager.transactionsAdapter(for: $0) }
                .compactMap { $0.transactionRecords }
        )
        .flatMap { Publishers.Sequence(sequence: $0) }
        .receive(on: RunLoop.main)
        .sink { [weak self] transactionRecord in
            guard let self = self else { return }
            let index = self.transactions.firstIndex { $0.timestamp ?? 1 < transactionRecord.timestamp ?? 1 } ?? self.transactions.endIndex
            self.transactions.insert(transactionRecord, at: index)
            self.applyFilterAndSort()
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
        case .send, .received, .swapped:
            newTransactions = newTransactions.filter { $0.type == TxType.typeFor(filter: txTypeFilter) }
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
                // Make sure that timestamp is not nil
                let date1 = record1.timestamp != nil ? Date(timeIntervalSince1970: TimeInterval(record1.timestamp!)) : Date.distantPast
                let date2 = record2.timestamp != nil ? Date(timeIntervalSince1970: TimeInterval(record2.timestamp!)) : Date.distantPast
                return isDescending ? (date1 < date2) : (date1 > date2)
            case .amount:
                // Make sure that amount is not nil
                let amount1 = record1.amount ?? 0
                let amount2 = record2.amount ?? 0
                return isDescending ? (amount1 < amount2) : (amount1 > amount2)
            case .coin:
                return !isDescending ? (record1.coin.code < record2.coin.code) : (record1.coin.code > record2.coin.code)
            }
        }
        
        self.filteredTransactions = newTransactions
    }
}

