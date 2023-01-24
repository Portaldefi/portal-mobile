//
//  IAdapterManager.swift
//  Portal
//
//  Created by farid on 9/19/22.
//

import Foundation
import Combine

protocol IAdapterManager: AnyObject {
    var adapterReady: CurrentValueSubject<Bool, Never> { get }
    func adapter(for wallet: Wallet) -> IAdapter?
    func adapter(for coin: Coin) -> IAdapter?
    func balanceAdapter(for wallet: Wallet) -> IBalanceAdapter?
    func transactionsAdapter(for wallet: Wallet) -> ITransactionsAdapter?
    func depositAdapter(for wallet: Wallet) -> IDepositAdapter?
    func refresh()
    func refreshAdapters(wallets: [Wallet])
    func refresh(wallet: Wallet)
}
