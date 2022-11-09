//
//  SendFlowError.swift
//  Portal
//
//  Created by farid on 9/12/22.
//

import Foundation

enum SendFlowError: Error {
    case insufficientAmount
    case addressIsntValid
    case error(String)
    
    var description: String {
        switch self {
        case .addressIsntValid:
            return "Recepient address is invalid."
        case .insufficientAmount:
            return "Insufficient amount."
        case .error(let msg):
            return msg
        }
    }
}
