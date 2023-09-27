//
//  AssetDetailsViewModel.swift
// Portal
//
//  Created by farid on 10/2/22.
//

import Foundation
import Combine
import BitcoinDevKit
import Factory

@Observable class AssetDetailsViewModel {
    @ObservationIgnored let coin: Coin
    
    public var goToReceive = false
    public var goSend: Bool = false {
        willSet {
            if newValue != goSend && newValue == false {
                Container.Scope.cached.reset()
            }
        }
    }
    public var transactions: [TransactionRecord] = []
    
    @ObservationIgnored private let transactionAdapter: ITransactionsAdapter
    @ObservationIgnored private var subscriptions = Set<AnyCancellable>()
        
    init(coin: Coin, transactionAdapter: ITransactionsAdapter) {
        self.coin = coin
        self.transactionAdapter = transactionAdapter
        
//        transactionAdapter.onTxsUpdate.sink { [unowned self] _ in
//            self.updateTransactions()
//        }
//        .store(in: &subscriptions)
        
        updateTransactions()
    }
        
    func updateTransactions() {
        let unconfirmedTxs = transactionAdapter.transactionRecords.filter{ $0.timestamp == nil }
        let confirmedTxs = transactionAdapter.transactionRecords.filter{ $0.timestamp != nil }.sorted{ $0.timestamp! > $1.timestamp! }
        
        DispatchQueue.main.async {
            self.transactions = unconfirmedTxs + confirmedTxs
        }
    }
    
    deinit {
        print("Asset details view model deinit")
    }
}

extension AssetDetailsViewModel {
    static func config(coin: Coin) -> AssetDetailsViewModel {
        let adapterManager: IAdapterManager = Container.adapterManager()
        let walletManager: IWalletManager = Container.walletManager()

        guard
            let wallet = walletManager.activeWallets.first(where: { $0.coin == coin }),
            let transactionsAdapter = adapterManager.transactionsAdapter(for: wallet)
        else {
            fatalError("coudn't fetch dependencies")
        }
        return AssetDetailsViewModel(coin: coin, transactionAdapter: transactionsAdapter)
    }
    
    static var mocked: AssetDetailsViewModel {
        AssetDetailsViewModel(coin: .bitcoin(), transactionAdapter: MockedAdapter())
    }
}
