//
//  BTCQRCodeAddressType.swift
//  Portal
//
//  Created by farid on 2/20/23.
//

import Foundation

enum BTCQRCodeAddressType: CaseIterable {
    case lightning, onChain, unified
    
    var title: String {
        switch self {
        case .lightning:
            return "Lightning"
        case .onChain:
            return "On Chain"
        case .unified:
            return "Unified"
        }
    }
    
    var description: String {
        switch self {
        case .lightning:
            return "Instant, with minimal fees. But not all services support it."
        case .onChain:
            return "Slower. Higher fees. Most services support it."
        case .unified:
            return "An unified QR for both Lightning & On Chain. Most services don’t support it, yet."
        }
    }
}
