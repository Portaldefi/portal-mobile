//
//  ICoinManager.swift
//  Portal
//
//  Created by Farid on 30.07.2021.
//

import Combine

protocol ICoinManager {
    var onCoinsUpdate: PassthroughSubject<[Coin], Never> { get }
    var walletCoins: [Coin] { get }
    var avaliableCoins: [Coin] { get }
}
