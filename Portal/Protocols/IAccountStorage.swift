//
//  IAccountStorage.swift
//  Portal
//
//  Created by farid on 9/19/22.
//

import Foundation

protocol IAccountStorage {
    var activeAccount: Account? { get }
    var allAccounts: [Account] { get }
    var activeAccountRecoveryData: RecoveryData? { get }
    func save(account: Account, mnemonic: String, salt: String?)
    func delete(account: Account)
    func clear()
    func setCurrentAccount(id: String)
    func update(account: Account)
}
