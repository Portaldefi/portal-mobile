//
//  CreateAccountViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import Foundation
import BitcoinDevKit

class CreateAccountViewModel: ObservableObject {
    @Published var accountName = String()
    @Published var extendedKey: ExtendedKeyInfo
    
    init() {
        extendedKey = try! generateExtendedKey(network: Network.testnet, wordCount: WordCount.words12, password: nil)
    }
    
    func createAccount() {
        let account = Account(id: UUID().uuidString, index: 0, name: accountName, key: extendedKey)
        Portal.shared.accountManager.save(account: account)
    }
}
