//
//  RecoveryData.swift
//  Portal
//
//  Created by farid on 11/29/22.
//

import Foundation

struct RecoveryData {
    let words: [String]
    let salt: String
    
    var recoveryString: String {
        words.joined(separator: " ")
    }
}
