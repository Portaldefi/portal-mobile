//
//  AccountManager.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import Combine

final class AccountManager {
    var onActiveAccountUpdate = PassthroughSubject<IAccount?, Never>()

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
    var activeAccount: IAccount? {
        accountStorage.activeAccount
    }
    
    var accounts: [IAccount] {
        accountStorage.allAccounts
    }
    
    func account(id: String) -> IAccount? {
        accounts.first(where: { $0.id == id })
    }
    
    func setActiveAccount(id: String) {
        accountStorage.setCurrentAccount(id: id)
        onActiveAccountUpdate.send(accountStorage.activeAccount)
    }
    
    func save(account: IAccount) {
        accountStorage.save(account: account)
        onActiveAccountUpdate.send(account)
    }
    
    func delete(account: IAccount) {
        accountStorage.delete(account: account)
        nextActiveAccount()
    }
    
    func update(account: IAccount) {
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
