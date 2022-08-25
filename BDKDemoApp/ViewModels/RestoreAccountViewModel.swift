//
//  RestoreAccountViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import Foundation
import Combine
import BitcoinDevKit
import Factory

class RestoreAccountViewModel: ObservableObject {
    @Published var accountName = String()
    @Published var seed = String()
    @Published var restorable = false
    
    @Injected(Container.service) private var service
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        Publishers.CombineLatest($accountName, $seed)
            .sink { [weak self] nameString, seedString in
                let wordsArray = seedString.components(separatedBy: " ").filter{ !$0.isEmpty && $0.count >= 3 }
                self?.restorable = !nameString.isEmpty && wordsArray.count == 12
            }
            .store(in: &subscriptions)
    }
    
    func restoreAccount() {
        let words = seed.components(separatedBy: " ").filter{ !$0.isEmpty && $0.count >= 3 }
        do {
            let restoredKey = try restoreExtendedKey(network: Network.testnet, mnemonic: words.joined(separator:" "), password: nil)
            let account = Account(id: UUID().uuidString, index: 0, name: accountName, key: restoredKey)
            service.accountManager.save(account: account)
        } catch {
            print("restore error: \(error)")
        }
    }
}
