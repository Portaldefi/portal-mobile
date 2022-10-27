//
//  CreateAccountViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import Foundation
import BitcoinDevKit
import Factory

class CreateAccountViewModel: ObservableObject {
    @Published var accountName = String()
    @Published var extendedKey: DescriptorSecretKey
    private let mnemonic: String
    
    @Injected(Container.accountManager) private var manager
    
    init() {
        mnemonic = try! generateMnemonic(wordCount: .words12)
        extendedKey = try! DescriptorSecretKey(network: .testnet, mnemonic: mnemonic, password: nil)
    }
    
    func createAccount() {
        let account = Account(id: UUID().uuidString, index: 0, name: accountName, key: extendedKey)
        manager.save(account: account, mnemonic: mnemonic, salt: nil)
    }
}
