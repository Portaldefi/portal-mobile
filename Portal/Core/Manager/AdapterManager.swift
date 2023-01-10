//
//  AdapterManager.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import Combine

final class AdapterManager {
    private var subscriptions = Set<AnyCancellable>()

    private let adapterFactory: IAdapterFactory
    private let walletManager: IWalletManager

    private let queue = DispatchQueue(label: "tides.universal.portal.adapter_manager", qos: .userInitiated)
    private var adapters = [Wallet: IAdapter]()
    
    var adapterReady = CurrentValueSubject<Bool, Never>(false)

    init(adapterFactory: IAdapterFactory, walletManager: IWalletManager) {
        self.adapterFactory = adapterFactory
        self.walletManager = walletManager
        
        initAdapters(wallets: walletManager.activeWallets)
        
        walletManager.onWalletsUpdate
            .receive(on: RunLoop.main)
            .sink { [weak self] wallets in
                self?.refreshAdapters(wallets: wallets)
            }
            .store(in: &subscriptions)
    }

    private func initAdapters(wallets: [Wallet]) {
        var newAdapters = queue.sync { adapters }

        for wallet in wallets {
            guard newAdapters[wallet] == nil else {
                continue
            }

            if let adapter = adapterFactory.adapter(wallet: wallet) {
                newAdapters[wallet] = adapter
                adapter.start()
            }
        }

        var removedAdapters = [IAdapter]()

        for wallet in Array(newAdapters.keys) {
            guard !wallets.contains(wallet), let adapter = newAdapters.removeValue(forKey: wallet) else {
                continue
            }

            removedAdapters.append(adapter)
        }

        queue.async {
            self.adapters = newAdapters
            self.adapterReady.send(true)
        }

        removedAdapters.forEach { adapter in
            adapter.stop()
        }
    }

}

extension AdapterManager: IAdapterManager {

    func adapter(for wallet: Wallet) -> IAdapter? {
        queue.sync { adapters[wallet] }
    }

    func adapter(for coin: Coin) -> IAdapter? {
        queue.sync {
            guard let wallet = walletManager.activeWallets.first(where: { $0.coin == coin } ) else {
                return nil
            }

            return adapters[wallet]
        }
    }

    func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter? {
        queue.sync { adapters[wallet] as? IBalanceAdapter }
    }

    func transactionsAdapter(for wallet: Wallet) -> ITransactionsAdapter? {
        queue.sync { adapters[wallet] as? ITransactionsAdapter }
    }

    func depositAdapter(for wallet: Wallet) -> IDepositAdapter? {
        queue.sync { adapters[wallet] as? IDepositAdapter }
    }
    
    func refresh() {
        queue.async {
            for adapter in self.adapters.values {
                adapter.refresh()
            }
        }
    }

    func refreshAdapters(wallets: [Wallet]) {
        queue.async {
            wallets.forEach {
                self.adapters[$0]?.stop()
                self.adapters[$0] = nil
            }
        }

        initAdapters(wallets: walletManager.activeWallets)
    }

    func refresh(wallet: Wallet) {
        adapters[wallet]?.refresh()
    }
}

extension AdapterManager {
    private class AdapterManagerMocked: IAdapterManager {        
        var adapterReady = CurrentValueSubject<Bool, Never>(true)
        
        func adapter(for wallet: Wallet) -> IAdapter? {
            nil
        }
        
        func adapter(for coin: Coin) -> IAdapter? {
            nil
        }
        
        func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter? {
            nil
        }
        
        func transactionsAdapter(for wallet: Wallet) -> ITransactionsAdapter? {
            nil
        }
        
        func depositAdapter(for wallet: Wallet) -> IDepositAdapter? {
            nil
        }
        
        func refresh() {
            
        }
        
        func refreshAdapters(wallets: [Wallet]) {
            
        }
        
        func refresh(wallet: Wallet) {
            
        }
    }
    
    static var mocked: IAdapterManager {
        AdapterManagerMocked()
    }
}
