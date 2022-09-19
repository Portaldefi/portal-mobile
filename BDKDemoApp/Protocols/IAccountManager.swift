//
//  IAcountManager.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import Combine

protocol IAccountManager {
    var onActiveAccountUpdate: PassthroughSubject<IAccount?, Never> { get }
    var accounts: [IAccount] { get }
    var activeAccount: IAccount? { get }
    func account(id: String) -> IAccount?
    func updateWalletCurrency(code: String)
    func addCoin(coin: String)
    func setActiveAccount(id: String)
    func save(account: IAccount)
    func update(account: IAccount)
    func delete(account: IAccount)
    func clear()
}

