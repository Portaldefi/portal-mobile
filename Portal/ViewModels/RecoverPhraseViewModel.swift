//
//  RecoverPhraseViewModel.swift
//  Portal
//
//  Created by farid on 11/29/22.
//

import Foundation
import SwiftUI
import Combine
import Factory

class RecoveryPhraseViewModel: ObservableObject {
    private let storage: ILocalStorage
    let recoveryPhrase: [String]
    let recoveryTest: [String]
    
    @Published var goToVerify = false
    @Published var goToWarnig = false
    @Published var recoveryArray = [String]()
    @Published var isCorrectSelection = true
    
    var testPassed: Bool {
        recoveryPhrase.hashValue == recoveryArray.hashValue
    }
    
    init(storage: ILocalStorage, recoveryPhrase: [String]) {
        self.storage = storage
        print("recoveryPhrase: \(recoveryPhrase)")
        self.recoveryPhrase = recoveryPhrase
        self.recoveryTest = recoveryPhrase.shuffled()
    }
    
    func select(word: String) {
        if let index = recoveryArray.firstIndex(of: word) {
            recoveryArray.remove(at: index)
            isCorrectSelection = true
        } else {
            guard isCorrectSelection else { return }
            recoveryArray.append(word)
            isCorrectSelection = isCorrectSelection(word: word)
        }
    }
    
    func indexOf(word: String) -> Int {
        if let index = recoveryArray.firstIndex(of: word) {
            return index + 1
        } else {
            return 1
        }
    }
        
    func isCorrectSelection(word: String) -> Bool {
        guard !recoveryArray.isEmpty else { return false }
        let index = indexOf(word: word)
        return recoveryPhrase[index - 1] == word
    }
    
    func markAccountAsBackedUp() {
        storage.markAccountIsBackeUp()
    }
}

extension RecoveryPhraseViewModel {
    static func config() -> RecoveryPhraseViewModel {
        let accountManager: IAccountManager = Container.accountManager()
        let userDefaults = UserDefaults.standard
        let localStorage = LocalStorage(storage: userDefaults)

        guard
            let recoveryData = accountManager.activeAccountRecoveryData
        else {
            fatalError("coudn't fetch dependencies")
        }
        
        return RecoveryPhraseViewModel(storage: localStorage, recoveryPhrase: recoveryData.words)
    }
}
