//
//  IFeeRateProvider.swift
//  Portal
//
//  Created by farid on 1/3/23.
//

import Foundation
import Combine

protocol IFeeRateProvider {
    var feeRatePriorityList: [FeeRatePriority] { get }
    var defaultFeeRatePriority: FeeRatePriority { get }
    func recommendedFeeRate() async throws -> Int
    func feeRate(priority: FeeRatePriority) async throws -> Int
}

extension IFeeRateProvider {
    var feeRatePriorityList: [FeeRatePriority] {
        [.recommended]
    }

    var defaultFeeRatePriority: FeeRatePriority {
        .recommended
    }

    func feeRate(priority: FeeRatePriority) async throws -> Int {
        if case let .custom(value, _) = priority {
            return value
        } else {
            return try await recommendedFeeRate()
        }
    }
}
