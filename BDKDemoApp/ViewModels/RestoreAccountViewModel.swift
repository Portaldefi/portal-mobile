//
//  RestoreAccountViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import Foundation
import Combine

class RestoreAccountViewModel: ObservableObject {
    @Published var accountName = String()
    @Published var seed = String()
    @Published var restorable: Bool = false
    
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
        print(words)
    }
}
