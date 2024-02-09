//
//  AssetViewModel.swift
// Portal
//
//  Created by farid on 10/2/22.
//

import Foundation
import Combine
import BitcoinDevKit
import Factory
import PortalSwapSDK

@Observable class AssetViewModel {
    let coin: Coin
    
    public var goToReceive = false
    public var goSend: Bool = false {
        willSet {
            if newValue != goSend && newValue == false {
                Container.Scope.cached.reset()
            }
        }
    }
    public var transactions: [TransactionRecord] = []
    public var selectedTx: TransactionRecord?
    
    @ObservationIgnored private let transactionAdapter: ITransactionsAdapter
    @ObservationIgnored private var persistenceManager: LocalPersistenceManager?
    @ObservationIgnored private let txDataStorage: ITxUserDataStorage

    @ObservationIgnored private var subscriptions = Set<AnyCancellable>()
    
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
        
    init(coin: Coin, transactionAdapter: ITransactionsAdapter) {
        self.coin = coin
        self.transactionAdapter = transactionAdapter
        persistenceManager = try? LocalPersistenceManager.manager()
        txDataStorage = Container.txDataStorage()
        subscribe()
    }
    
    func subscribe() {
        transactionAdapter
            .onTxsUpdate
            .receive(on: RunLoop.main)
            .sink
        { [weak self] _ in
            self?.updateTransactions()
        }
        .store(in: &subscriptions)
    }
        
    func updateTransactions() {
        let unconfirmedTxs = transactionAdapter.transactionRecords.filter{ $0.timestamp == nil }
        let confirmedTxs = transactionAdapter.transactionRecords.filter{ $0.timestamp != nil }
        
        var swapRecords = [SwapTransactionRecord]()
        
        if let manager = persistenceManager {
            if let swaps = try? manager.fetchSwaps() {
                for swap in swaps {
                    let source: TxSource = .swap(base: .lightningBitcoin(), quote: .ethereum())
                    let data = txDataStorage.fetch(source: source, id: swap.swapId)
                    let userData = TxUserData(data: data)
                    let swapRecord = SwapTransactionRecord(swap: swap, userData: userData)
                    
                    swapRecords.append(swapRecord)
                }
            }
        }
        
        let allSwapsIds = swapRecords.map{ $0.id }
        var swapIds = [String]()
        
        let filteredTxs = (unconfirmedTxs + confirmedTxs).filter {
            switch $0 {
            case let record as EvmTransactionRecord:
                guard record.receiver == swapContractAddress else { return true }
                if let swapRecord = swapRecords.first(where: { $0.baseQuantity == record.amount }) {
                    swapIds.append(swapRecord.id)
                }
                return false
            case let record as LNTransactionRecord:
                guard allSwapsIds.contains(record.memo ?? String()) else { return true }
                swapIds.append(record.memo!)
                return false
            default:
                return true
            }
        }
        
        let allTxs = (filteredTxs + swapRecords.filter{ swapIds.contains($0.id) })
            .sorted{ $0.timestamp ?? Int(Date().timeIntervalSince1970) > $1.timestamp ?? Int(Date().timeIntervalSince1970) }
        
        DispatchQueue.main.async {
            self.transactions = allTxs
        }
    }
    
    deinit {
        print("Asset details view model deinit")
    }
}

extension AssetViewModel {
    static func config(coin: Coin) -> AssetViewModel {
        let adapterManager: IAdapterManager = Container.adapterManager()
        let walletManager: IWalletManager = Container.walletManager()

        guard
            let wallet = walletManager.activeWallets.first(where: { $0.coin == coin }),
            let transactionsAdapter = adapterManager.transactionsAdapter(for: wallet)
        else {
            fatalError("coudn't fetch dependencies")
        }
        return AssetViewModel(coin: coin, transactionAdapter: transactionsAdapter)
    }
    
    static var mocked: AssetViewModel {
        AssetViewModel(coin: .bitcoin(), transactionAdapter: MockedAdapter())
    }
}
