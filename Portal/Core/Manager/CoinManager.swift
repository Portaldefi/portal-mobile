//
//  CoinManager.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import SwiftUI
import Combine
import Factory

final class CoinManager: ICoinManager {
    var onCoinsUpdate = PassthroughSubject<[Coin], Never>()
    
    private let storage: ICoinStorage
    private let accountManager: IAccountManager
    private let settings: IPortalSettings
    private var subscriptions = Set<AnyCancellable>()
    
    var walletCoins: [Coin] = []
    
    var avaliableCoins: [Coin] {
        storage.coins.value
    }
    
    init(storage: ICoinStorage, accountManager: IAccountManager, userSettings: IPortalSettings) {
        self.storage = storage
        self.accountManager = accountManager
        self.settings = userSettings
        self.syncCoins(userSettings.userCoins.value)
        self.subscribe()
    }
    
    private func subscribe() {
        storage.coins
            .sink { [unowned self] coins in
                syncCoins(coins.map{ $0.code })
            }
            .store(in: &subscriptions)
        
        accountManager.onActiveAccountUpdate
            .sink { [unowned self] _ in
                syncCoins(settings.userCoins.value)
            }
            .store(in: &subscriptions)
    }
    
    private func syncCoins(_ coinCodes: [String]) {
        walletCoins.removeAll()
        
        walletCoins.append(.bitcoin())
        walletCoins.append(.ethereum())
        
        for code in coinCodes {
            guard let coin = avaliableCoins.first(where: { $0.code == code }) else { return }
            walletCoins.append(coin)
        }
        
        onCoinsUpdate.send(walletCoins)
    }
}

class CoinManagerMocked: ICoinManager {
    var onCoinsUpdate = PassthroughSubject<[Coin], Never>()
    var walletCoins: [Coin] = [.bitcoin(), .ethereum()]
    
    var avaliableCoins: [Coin] = [
        Coin(
            type: .erc20(address: "0x326C977E6efc84E512bB9C30f76E30c160eD06FB"),
            code: "LINK",
            name: "Chainlink Token",
            decimal: 18,
            iconUrl: "https://images.cointelegraph.com/images/1200_aHR0cHM6Ly9zMy5jb2ludGVsZWdyYXBoLmNvbS9zdG9yYWdlL3VwbG9hZHMvdmlldy9hNmRhMjI1NTRkMjBkZDdjNTg4NDM0N2IwMTcyN2ExMi5wbmc=.jpg"
        ),
        Coin(
            type: .erc20(address: "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"),
            code: "UNI",
            name: "Uniswap Token",
            decimal: 18,
            iconUrl: "https://www.crypto-nation.io/cn-files/uploads/2021/01/Uniswap-Logo.png"
        ),
        Coin(
            type: .erc20(address: "0xB8c77482e45F1F44dE1745F52C74426C631bDD52"),
            code: "BNB",
            name: "Binance Token",
            decimal: 18,
            iconUrl: "https://www.crypto-nation.io/cn-files/uploads/2021/01/Uniswap-Logo.png"
        ),
        Coin(
            type: .erc20(address: "0xc00e94Cb662C3520282E6f5717214004A7f26888"),
            code: "COMP",
            name: "Compound",
            decimal: 18,
            iconUrl: "https://www.crypto-nation.io/cn-files/uploads/2021/01/Uniswap-Logo.png"
        )
    ]
    
    init() {}
}
