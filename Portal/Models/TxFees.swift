//
//  TxFees.swift
//  Portal
//
//  Created by farid on 1/9/23.
//

import Foundation

enum TxFees {
    case fast, normal, slow, custom
    
    var description: String {
        switch self {
        case .fast:
            return "Fast ~ 10 mins"
        case .normal:
            return "Normal ~ 30 mins"
        case .slow:
            return "Slow ~ 60 mins"
        case .custom:
            return "Not implemented"
        }
    }
}
