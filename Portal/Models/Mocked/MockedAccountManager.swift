//
//  MockedAccountManager.swift
//  UnitTestsMacOS
//
//  Created by farid on 1/21/22.
//

import Foundation
import Combine

struct MockedAccountManager: IAccountManager {
    var activeAccountRecoveryData: RecoveryData?
    
    private let mockedAccount = Account(id: UUID().uuidString, index: 0, name: "Mocked", key: UUID().uuidString)
    private let accountToSave = Account(id: UUID().uuidString, index: 0, name: "Account to save", key: UUID().uuidString)
    private let accountToDelete = Account(id: UUID().uuidString, index: 0, name: "Account to delete", key: UUID().uuidString)
    
    var onActiveAccountUpdate: PassthroughSubject<Account?, Never> = PassthroughSubject<Account?, Never>()
    
    var accounts: [Account] {
        [mockedAccount]
    }
    
    var activeAccount: Account? {
        mockedAccount
    }
    
    func addCoin(coin: String) {
        
    }
    
    func account(id: String) -> Account? {
        mockedAccount
    }
    
    func updateWalletCurrency(code: String) {
        
    }
    
    func setActiveAccount(id: String) {
        onActiveAccountUpdate.send(accountToSave)
    }
    
    func save(account: Account) {
        onActiveAccountUpdate.send(accountToDelete)
    }
    
    func save(account: Account, mnemonic: String, salt: String?) {
        
    }
    
    func update(account: Account) {
        
    }
    
    func delete(account: Account) {
        onActiveAccountUpdate.send(accountToDelete)
    }
    
    func delete(accountId: String) {
        
    }
    
    func clear() {
        
    }
}
