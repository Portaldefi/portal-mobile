//
//  WalletManager.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import Combine

final class WalletManager {
    var onWalletsUpdate = PassthroughSubject<[Wallet], Never>()
    
    private let accountManager: IAccountManager
    private let storage: IWalletStorage
    private var subscriptions = Set<AnyCancellable>()

    private let subject = PassthroughSubject<[Wallet], Never>()

    private let queue = DispatchQueue(label: "tides.universal.portal.wallet_manager", qos: .userInitiated)

    private var cachedWallets = [Wallet]()
    private var cachedActiveWallets = [Wallet]()

    init(accountManager: IAccountManager, storage: IWalletStorage) {
        self.accountManager = accountManager
        self.storage = storage
        
        cachedWallets = storage.wallets
        handleUpdate(activeAccount: accountManager.activeAccount)

        storage.onWalletsUpdate
            .sink { [weak self] _ in
                self?.handleUpdate(activeAccount: accountManager.activeAccount)
            }
            .store(in: &subscriptions)
    }

    private func notify() {
        subject.send(cachedWallets)
    }

    private func notifyActiveWallets() {
        onWalletsUpdate.send(cachedActiveWallets)
    }

    private func handleUpdate(activeAccount: Account?) {
        let activeWallets = activeAccount.map { storage.wallets(account: $0) } ?? []

        queue.sync {
            self.cachedActiveWallets = activeWallets
            self.notifyActiveWallets()
        }
    }

}

extension WalletManager: IWalletManager {
    var activeWallets: [Wallet] {
        queue.sync { cachedActiveWallets }
    }

    var wallets: [Wallet] {
        queue.sync { cachedWallets }
    }

    func preloadWallets() {
        queue.async {
            self.cachedWallets = self.storage.wallets
            self.notify()
        }
    }

    func wallets(account: Account) -> [Wallet] {
        storage.wallets(account: account)
    }

    func handle(newWallets: [Wallet], deletedWallets: [Wallet]) {
        storage.handle(newWallets: newWallets, deletedWallets: deletedWallets)

        queue.async {
            self.cachedWallets.append(contentsOf: newWallets)
            self.cachedWallets.removeAll { deletedWallets.contains($0) }
            self.notify()

            let activeAccount = self.accountManager.activeAccount
            self.cachedActiveWallets.append(contentsOf: newWallets.filter { $0.account == activeAccount })
            self.cachedActiveWallets.removeAll { deletedWallets.contains($0) }
            self.notifyActiveWallets()
        }
    }

    func save(wallets: [Wallet]) {
        handle(newWallets: wallets, deletedWallets: [])
    }

    func delete(wallets: [Wallet]) {
        handle(newWallets: [], deletedWallets: wallets)
    }

    func clearWallets() {
        storage.clearWallets()
    }
}

extension WalletManager {
    private class WalletManagerMocked: IWalletManager {
        var onWalletsUpdate = PassthroughSubject<[Wallet], Never>()
        
        var activeWallets: [Wallet] = []
        
        var wallets: [Wallet] = []
        
        func preloadWallets() {
            
        }
        
        func wallets(account: Account) -> [Wallet] {
            []
        }
        
        func handle(newWallets: [Wallet], deletedWallets: [Wallet]) {
            
        }
        
        func save(wallets: [Wallet]) {
            
        }
        
        func delete(wallets: [Wallet]) {
            
        }
        
        func clearWallets() {
            
        }
    }
    static var mocked: IWalletManager {
        WalletManagerMocked()
    }
}
