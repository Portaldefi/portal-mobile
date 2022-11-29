//
//  IAcountManager.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import Combine

protocol IAccountManager {
    var onActiveAccountUpdate: PassthroughSubject<Account?, Never> { get }
    var accounts: [Account] { get }
    var activeAccount: Account? { get }
    var activeAccountRecoveryData: RecoveryData? { get }
    func account(id: String) -> Account?
    func updateWalletCurrency(code: String)
    func addCoin(coin: String)
    func setActiveAccount(id: String)
    func save(account: Account, mnemonic: String, salt: String?)
    func update(account: Account)
    func delete(account: Account)
    func clear()
}

