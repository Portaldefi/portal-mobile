//
//  AccountStorage.swift
//  Portal
//
//  Created by Farid on 22.07.2021.
//

import Foundation
import BitcoinDevKit

class AccountStorage {
    private let localStorage: ILocalStorage
    private let secureStorage: IKeychainStorage
    private let accountStorage: IAccountRecordStorage

    init(localStorage: ILocalStorage, secureStorage: IKeychainStorage, accountStorage: IAccountRecordStorage) {
        self.localStorage = localStorage
        self.secureStorage = secureStorage
        self.accountStorage = accountStorage
    }

    private func createAccount(record: AccountRecord) -> Account? {
        guard let recoveryData = recoveryData(recordId: record.id) else { return nil }
        let mnemonic = try! Mnemonic.fromString(mnemonic: recoveryData.recoveryString)
        let key = DescriptorSecretKey(network: .testnet, mnemonic: mnemonic, password: recoveryData.salt)
        return Account(record: record, key: key)
    }
    
    private func recoveryData(recordId: String) -> RecoveryData? {
        guard let words = recoverStringArray(id: recordId, typeName: .mnemonic, keyName: .words) else {
            return nil
        }
                
        guard let salt: String = recover(id: recordId, typeName: .mnemonic, keyName: .salt) else {
            return nil
        }
        
        return RecoveryData(words: words, salt: salt)
    }

    private func createRecord(account: Account, mnemonic: String, salt: String?) throws -> AccountRecord {
        let typeName: TypeName = .mnemonic
        _ = try store(stringArray: mnemonic.components(separatedBy: " "), id: account.id, typeName: typeName, keyName: .words)
        _ = try store(salt != nil ? salt! : String(), id: account.id, typeName: typeName, keyName: .salt)
        return AccountRecord(id: account.id, index: account.index, name: account.name, context: accountStorage.context)
    }

    private func clearSecureStorage(account: Account) throws {
        let id = account.id
        try secureStorage.removeValue(for: secureKey(id: id, typeName: .mnemonic, keyName: .words))
        try secureStorage.removeValue(for: secureKey(id: id, typeName: .mnemonic, keyName: .salt))
    }

    private func secureKey(id: String, typeName: TypeName, keyName: KeyName) -> String {
        "\(keyName.rawValue)_\(id)_\(typeName.rawValue)"
    }

    private func store(stringArray: [String], id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        try store(stringArray.joined(separator: ","), id: id, typeName: typeName, keyName: keyName)
    }

    private func store<T: LosslessStringConvertible>(_ value: T, id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        try secureStorage.set(value: value, for: key)
        return key
    }

    private func store(data: Data, id: String, typeName: TypeName, keyName: KeyName) throws -> String {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        try secureStorage.set(value: data, for: key)
        return key
    }

    private func recoverStringArray(id: String, typeName: TypeName, keyName: KeyName) -> [String]? {
        let string: String? = recover(id: id, typeName: typeName, keyName: keyName)
        return string?.split(separator: ",").map { String($0) }
    }

    private func recover<T: LosslessStringConvertible>(id: String, typeName: TypeName, keyName: KeyName) -> T? {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        return secureStorage.value(for: key)
    }

    private func recoverData(id: String, typeName: TypeName, keyName: KeyName) -> Data? {
        let key = secureKey(id: id, typeName: typeName, keyName: keyName)
        return secureStorage.value(for: key)
    }
}

extension AccountStorage: IAccountStorage {
    var activeAccountRecoveryData: RecoveryData? {
        guard
            let currentAccountID = localStorage.getCurrentAccountID(),
            let record = accountStorage.accountRecords.first(where: { $0.id == currentAccountID })
        else { return nil }
        
        return recoveryData(recordId: record.id)
    }
    
    var activeAccount: Account? {
        guard
            let currentAccountID = localStorage.getCurrentAccountID(),
            let record = accountStorage.accountRecords.first(where: { $0.id == currentAccountID })
        else { return nil }
        
        return createAccount(record: record)
    }

    var allAccounts: [Account] {
        accountStorage.accountRecords.compactMap { createAccount(record: $0) }
    }

    func save(account: Account, mnemonic: String, salt: String?) {
        if let record = try? createRecord(account: account, mnemonic: mnemonic, salt: salt) {
            accountStorage.save(accountRecord: record)
            localStorage.setCurrentAccountID(record.id)
        }
    }

    func delete(account: Account) {
        try? accountStorage.deleteAccount(account)
        try? clearSecureStorage(account: account)
    }

    func clear() {
        accountStorage.deleteAllAccountRecords()
    }
    
    func setCurrentAccount(id: String) {
        localStorage.setCurrentAccountID(id)
    }

    func update(account: Account) {
        accountStorage.update(account: account)
    }
}

extension AccountStorage {
    private enum TypeName: String {
        case mnemonic
        case privateKey
    }

    private enum KeyName: String {
        case words
        case salt
        case data
        case privateKey
    }
}

extension AccountStorage {
    static var mocked: IAccountStorage {
        AccountStorage(
            localStorage: LocalStorage.mocked,
            secureStorage: KeychainStorage.mocked,
            accountStorage: DBlocalStorage.mocked
        )
    }
}
