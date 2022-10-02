//
//  AssetDetailsViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 10/2/22.
//

import Foundation
import Combine
import BitcoinDevKit

class AssetDetailsViewModel: ObservableObject {
    let coin: Coin
    
    @Published private(set) var transactions: [BitcoinDevKit.Transaction] = []
    
    private let transactionAdapter: ITransactionsAdapter
    private var subscriptions = Set<AnyCancellable>()
    
    init(coin: Coin, transactionAdapter: ITransactionsAdapter) {
        self.coin = coin
        self.transactionAdapter = transactionAdapter
        
        subscribe()
    }
    
    private func subscribe() {
        transactionAdapter
            .transactionRecords
            .assign(to: &$transactions)
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
}