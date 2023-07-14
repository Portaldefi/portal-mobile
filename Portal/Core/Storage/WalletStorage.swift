//
//  WalletStorage.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import Combine

class WalletStorage: IWalletStorage {
    var wallets: [Wallet] = []
    var onWalletsUpdate = PassthroughSubject<[Wallet], Never>()
    
    private let coinManager: ICoinManager
    private let accountManager: IAccountManager
    
    private var subscriptions = Set<AnyCancellable>()

    init(coinManager: ICoinManager, accountManager: IAccountManager) {
        self.coinManager = coinManager
        self.accountManager = accountManager
        
        syncWallets()
        subscribeForUpdates()
    }
    
    private func subscribeForUpdates() {
        accountManager.onActiveAccountUpdate.map { _ in () }  // map to Void
            .merge(with: coinManager.onCoinsUpdate.map { _ in () })  // map to Void
            .sink { [weak self] _ in
                self?.syncWallets()
            }
            .store(in: &subscriptions)
    }
    
    private func syncWallets() {
        wallets.removeAll()
        
        for account in accountManager.accounts {
            for coin in coinManager.walletCoins {
                wallets.append(Wallet(coin: coin, account: account))
            }
        }
        
        onWalletsUpdate.send(wallets)
    }
    
    func wallets(account: Account) -> [Wallet] {
        wallets.filter{ $0.account == account }
    }
    
    func clearWallets() {
        wallets.removeAll()
    }
    
    func handle(newWallets: [Wallet], deletedWallets: [Wallet]) {
        
    }
}

