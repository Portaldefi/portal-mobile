//
//  CoinManager.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import SwiftUI
import Combine

final class CoinManager: ICoinManager {
    var onCoinsUpdate = PassthroughSubject<[Coin], Never>()
    
    private let storage: ICoinStorage
    private let accountManager: IAccountManager
    private var subscriptions = Set<AnyCancellable>()
    
    var walletCoins: [Coin] = []
    
    var avaliableCoins: [Coin] {
        storage.coins.value
    }
    
    init(storage: ICoinStorage, accountManager: IAccountManager) {
        self.storage = storage
        self.accountManager = accountManager
        self.syncCoins(account: accountManager.activeAccount)
        self.subscribe()
    }
    
    private func subscribe() {
        storage.coins
            .sink { [weak self] coins in
                guard let self = self else { return }
                self.syncCoins(account: self.accountManager.activeAccount)
            }
            .store(in: &subscriptions)
        
        accountManager.onActiveAccountUpdate
            .sink { [weak self] account in
                guard let account = account else { return }
                self?.syncCoins(account: account)
            }
            .store(in: &subscriptions)
    }
    
    private func syncCoins(account: Account?) {
        guard let account = account else { return }
        
        walletCoins.removeAll()
        
//        for code in account.coins.sorted(by: { $0 < $1 }) {
//            switch code {
//            case "BTC":
//                walletCoins.append(.bitcoin())
//            case "ETH":
//                walletCoins.append(.ethereum())
//            default:
//                guard let coin = avaliableCoins.first(where: { $0.code == code }) else { return }
//                walletCoins.append(coin)
//            }
//        }
        
        onCoinsUpdate.send(walletCoins)
    }
    
    private func sadas() {
        
    }
}

class CoinManagerMocked: ICoinManager {
    var onCoinsUpdate = PassthroughSubject<[Coin], Never>()
    var walletCoins: [Coin] = [.bitcoin(), .ethereum()]
    var avaliableCoins: [Coin] = [.bitcoin()]
    
    init() {}
}
