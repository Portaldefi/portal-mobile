//
//  Account.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import BitcoinDevKit
import EvmKit
import Factory

class Account {
    let id: String
    let index: Int
    let rootKey: String
    
    @Injected(Container.configProvider) var config

    private(set) var name: String
    
    var btcNetwork: BitcoinDevKit.Network {
        switch config.network {
        case .mainnet:
            return .bitcoin
        case .testnet:
            return .testnet
        case .playnet:
            return .regtest
        }
    }
    
    var ethNetwork: EvmKit.Chain {
        switch config.network {
        case .mainnet:
            return .ethereum
        case .testnet:
            return .ethereumSepolia
        case .playnet:
            return .ethereumPlaynet
        }
    }

    init(id: String, index: Int, name: String, key: String) {
        self.id = id
        self.index = index
        self.name = name
        self.rootKey = key
    }
    
    init(record: AccountRecord, key: String) {
        self.id = record.id
        self.index = Int(record.index)
        self.name = record.name
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
        let id = "MockedAccountID"
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
