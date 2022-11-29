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
    let recoveryPhrase: [String]
    
    init(recoveryPhrase: [String]) {
        self.recoveryPhrase = recoveryPhrase
    }
}

extension RecoveryPhraseViewModel {
    static func config() -> RecoveryPhraseViewModel {
        let accountManager: IAccountManager = Container.accountManager()

        guard
            let recoveryData = accountManager.activeAccountRecoveryData
        else {
            fatalError("coudn't fetch dependencies")
        }
        
        return RecoveryPhraseViewModel(recoveryPhrase: recoveryData.words)
    }
}
