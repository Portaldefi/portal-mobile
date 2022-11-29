//
//  RecoverPhraseViewModel.swift
//  Portal
//
//  Created by farid on 11/29/22.
//

import Foundation
import SwiftUI
import Combine

class RecoveryPhraseViewModel: ObservableObject {
    @Published var seed = [String]()
    
}

extension RecoveryPhraseViewModel {
    static func config() -> RecoveryPhraseViewModel {
        RecoveryPhraseViewModel()
    }
}
