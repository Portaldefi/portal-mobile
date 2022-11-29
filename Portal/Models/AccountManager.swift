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

    private let accountStorage: IAccountStorage
    
    init(accountStorage: IAccountStorage) {
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
    var activeAccountRecoveryData: RecoveryData? {
        accountStorage.activeAccountRecoveryData
    }
    
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
    
    func save(account: Account, mnemonic: String, salt: String?) {
        accountStorage.save(account: account, mnemonic: mnemonic, salt: salt)
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

extension AccountManager {
    private class AccountManagerMock: IAccountManager {
        var activeAccountRecoveryData: RecoveryData? {
            RecoveryData(words: ["point", "head", "pencil", "differ", "reopen", "damp", "wink", "minute", "improve", "toward", "during", "term"], salt: String())
        }
        
        var onActiveAccountUpdate = PassthroughSubject<Account?, Never>()
        
        var accounts: [Account] = []
        
        var activeAccount: Account? = Account.mocked
        
        func account(id: String) -> Account? {
            nil
        }
        
        func updateWalletCurrency(code: String) {
            
        }
        
        func addCoin(coin: String) {
            
        }
        
        func setActiveAccount(id: String) {
            
        }
        
        func save(account: Account, mnemonic: String, salt: String?) {
            
        }
        
        func update(account: Account) {
            
        }
        
        func delete(account: Account) {
            
        }
        
        func clear() {
            
        }
    }
    
    static var mocked: IAccountManager {
        AccountManagerMock()
    }
}
