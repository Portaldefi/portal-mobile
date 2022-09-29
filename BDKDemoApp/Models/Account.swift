//
//  Account.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import BitcoinDevKit

class Account {
    let id: String
    let index: Int
    let extendedKey: ExtendedKeyInfo

    private(set) var name: String
    
    private let btcNetwork: Int
    private let ethNetwork: Int

    init(id: String, index: Int, name: String, key: ExtendedKeyInfo) {
        self.id = id
        self.index = index
        self.name = name
        self.btcNetwork = 1 //testNet
        self.ethNetwork = 1 //ropsten
        self.extendedKey = key
    }
    
    init(record: AccountRecord, key: ExtendedKeyInfo) {
        self.id = record.id
        self.index = Int(record.index)
        self.name = record.name
        self.btcNetwork = 1 //testNet
        self.ethNetwork = 1 //ropsten
        self.extendedKey = key
    }
}

extension Account: Hashable {
    public static func ==(lhs: Account, rhs: Account) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Account {
    static var mocked: Account {
        let id = UUID().uuidString
        let index = 0
        let name = "Mocked"
        let key = ExtendedKeyInfo(mnemonic: "", xprv: "", fingerprint: "")
        
        return Account(
            id: id,
            index: index,
            name: name,
            key: key
        )
    }
}
