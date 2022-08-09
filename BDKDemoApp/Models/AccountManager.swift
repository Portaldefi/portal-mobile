//
//  AccountManager.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import Combine

final class AccountManager {
    var onActiveAccountUpdate = PassthroughSubject<Account?, Never>()

    private let accountStorage: AccountStorage
    
    init(accountStorage: AccountStorage) {
        self.accountStorage = accountStorage
    }
        
    private func nextActiveAccount(previousAccountId: String? = nil) {
        if let newAccountId = accounts.filter({ $0.id != previousAccountId }).first?.id {
            setActiveAccount(id: newAccountId)
        } else {
            DispatchQueue.main.async {
                
            }
        }
    }
}

extension AccountManager: IAccountManager {
    var activeAccount: Account? {
        accountStorage.activeAccount
    }
    
    var accounts: [Account] {
        accountStorage.allAccounts
    }
    
    func account(id: String) -> Account? {
        accounts.first(where: { $0.id == id })
    }
    
    func setActiveAccount(id: String) {
        accountStorage.setCurrentAccount(id: id)
        onActiveAccountUpdate.send(accountStorage.activeAccount)
    }
    
    func save(account: Account) {
        accountStorage.save(account: account)
        onActiveAccountUpdate.send(account)
    }
    
    func delete(account: Account) {
        accountStorage.delete(account: account)
        nextActiveAccount()
    }
    
    func update(account: Account) {
        accountStorage.update(account: account)
        onActiveAccountUpdate.send(account)
    }
    
    func updateWalletCurrency(code: String) {
        
    }
    
    func clear() {
        accountStorage.clear()
    }
    
    func addCoin(coin: String) {
        
    }
}
