//
//  FeeRatePriority.swift
//  Portal
//
//  Created by farid on 1/3/23.
//

import Foundation

enum FeeRatePriority: Equatable {
    case low
    case medium
    case recommended
    case high
    case custom(value: Int, range: ClosedRange<Int>)

    var title: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .recommended: return "Recommended"
        case .high: return "High"
        case .custom: return "Custom"
        }
    }

    static func ==(lhs: FeeRatePriority, rhs: FeeRatePriority) -> Bool {
        switch (lhs, rhs) {
        case (.low, .low): return true
        case (.medium, .medium): return true
        case (.recommended, .recommended): return true
        case (.high, .high): return true
        case (.custom, .custom): return true
        default: return false
        }
    }
}
