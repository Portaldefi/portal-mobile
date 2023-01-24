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
    let rootKey: DescriptorSecretKey

    private(set) var name: String
    
    private let btcNetwork: Int
    private let ethNetwork: Int

    init(id: String, index: Int, name: String, key: DescriptorSecretKey) {
        self.id = id
        self.index = index
        self.name = name
        self.btcNetwork = 1 //testNet
        self.ethNetwork = 1 //ropsten
        self.rootKey = key
    }
    
    init(record: AccountRecord, key: DescriptorSecretKey) {
        self.id = record.id
        self.index = Int(record.index)
        self.name = record.name
        self.btcNetwork = 1 //testNet
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
        let id = UUID().uuidString
        let index = 0
        let name = "Mocked"
        let mnemonic = Mnemonic(wordCount: .words12)
        let key = DescriptorSecretKey(network: .testnet, mnemonic: mnemonic, password: nil)
        
        return Account(
            id: id,
            index: index,
            name: name,
            key: key
        )
    }
}
