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
    let rootKey: String

    private(set) var name: String
    
    let btcNetwork: Network
    private let ethNetwork: Int

    init(id: String, index: Int, name: String, key: String) {
        self.id = id
        self.index = index
        self.name = name
        self.btcNetwork = .regtest
        self.ethNetwork = 1 //ropsten
        self.rootKey = key
    }
    
    init(record: AccountRecord, key: String) {
        self.id = record.id
        self.index = Int(record.index)
        self.name = record.name
        self.btcNetwork = .regtest
        self.ethNetwork = 1 //ropsten
        self.rootKey = key
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
        let id = "Mocked Account ID"
        let index = 0
        let name = "Mocked"
        let mnemonic = Mnemonic(wordCount: .words12)
        let key = DescriptorSecretKey(network: .regtest, mnemonic: mnemonic, password: nil).asString()
        
        return Account(
            id: id,
            index: index,
            name: name,
            key: key
        )
    }
}
