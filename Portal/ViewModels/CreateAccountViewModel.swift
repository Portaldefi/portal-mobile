//
//  CreateAccountViewModel.swift
// Portal
//
//  Created by farid on 8/9/22.
//

import Foundation
import BitcoinDevKit
import Factory

class CreateAccountViewModel: ObservableObject {
    @Published var accountName = String()
    @Published var extendedKey: DescriptorSecretKey
    private let mnemonic: Mnemonic
    
    @Injected(Container.accountManager) private var manager
    
    init(words: [String]? = nil) {
        do {
            if let words = words {
                mnemonic = try Mnemonic.fromString(mnemonic: words.joined(separator: " "))
            } else {
                mnemonic = Mnemonic(wordCount: .words12)
            }
        } catch {
            fatalError("Mnemonic creating error: \(error)")
        }
        print("\(mnemonic.asString())")
        extendedKey = DescriptorSecretKey(network: .testnet, mnemonic: mnemonic, password: nil)
    }
    
    func createAccount() {
        let account = Account(id: UUID().uuidString, index: 0, name: accountName, key: extendedKey)
        manager.save(account: account, mnemonic: mnemonic.asString(), salt: nil)
    }
}
