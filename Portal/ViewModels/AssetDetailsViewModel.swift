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

class AssetDetailsViewModel: ObservableObject {
    let coin: Coin
    let walletItems: [WalletItem]
    
    @Published var goToReceive = false
    @Published var goSend: Bool = false {
        willSet {
            if newValue != goSend && newValue == false {
                Container.Scope.cached.reset()
            }
        }
    }
    @Published private(set) var transactions: [TransactionRecord] = []
    
    private let transactionAdapter: ITransactionsAdapter
    private var subscriptions = Set<AnyCancellable>()
    
    private var receiveViewModel: ReceiveViewModel?
    
    init(coin: Coin, transactionAdapter: ITransactionsAdapter, walletItems: [WalletItem]) {
        self.coin = coin
        self.transactionAdapter = transactionAdapter
        self.walletItems = walletItems
        
        subscribe()
    }
    
    private func subscribe() {
        transactionAdapter
            .transactionRecords
            .receive(on: RunLoop.main)
            .assign(to: &$transactions)
    }
    
    func updateTransactions() {
        subscribe()
    }
    
    func cleanup() {
        receiveViewModel = nil
    }
    
    func receviewVM() -> ReceiveViewModel {
        guard let vm = receiveViewModel else {
            receiveViewModel = ReceiveViewModel.config(items: walletItems, selectedItem: walletItems.first{ $0.coin == coin })
            return receiveViewModel!
        }
        return vm
    }
    
    deinit {
        print("Asset details view model deinit")
    }
}

extension AssetDetailsViewModel {
    static func config(coin: Coin) -> AssetDetailsViewModel {
        let adapterManager: IAdapterManager = Container.adapterManager()
        let walletManager: IWalletManager = Container.walletManager()
        let account = Container.accountViewModel()

        guard
            let wallet = walletManager.activeWallets.first(where: { $0.coin == coin }),
            let transactionsAdapter = adapterManager.transactionsAdapter(for: wallet)
        else {
            fatalError("coudn't fetch dependencies")
        }
        return AssetDetailsViewModel(coin: coin, transactionAdapter: transactionsAdapter, walletItems: account.items)
    }
    
    static var mocked: AssetDetailsViewModel {
        AssetDetailsViewModel(coin: .bitcoin(), transactionAdapter: MockedAdapter(), walletItems: [WalletItem.mockedBtc])
    }
}
