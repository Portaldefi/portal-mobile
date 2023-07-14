//
//  MockedCoinManager.swift
//  Portal
//
//  Created by farid on 14.07.2023.
//

import Foundation
import Combine

class MockedCoinManager: ICoinManager {
    var walletCoins = [Coin]()
    var avaliableCoins = [Coin]()
    var onCoinsUpdate = PassthroughSubject<[Coin], Never>()
    
    func addCoins() {
        walletCoins = [.bitcoin(), .ethereum()]
        onCoinsUpdate.send(walletCoins)
    }
    
    func removeCoins() {
        walletCoins.removeAll()
        onCoinsUpdate.send(walletCoins)
    }
}
