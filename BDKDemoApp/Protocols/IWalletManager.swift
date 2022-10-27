//
//  IWalletManager.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import Combine

protocol IWalletManager: AnyObject {
    var onWalletsUpdate: PassthroughSubject<[Wallet], Never> { get }
    var activeWallets: [Wallet] { get }
    var wallets: [Wallet] { get }
    func preloadWallets()
    func wallets(account: Account) -> [Wallet]
    func handle(newWallets: [Wallet], deletedWallets: [Wallet])
    func save(wallets: [Wallet])
    func delete(wallets: [Wallet])
    func clearWallets()
}
