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
    var recommendedFeeRate: Future<Int, Never> { get }
    func feeRate(priority: FeeRatePriority) -> Future<Int, Never>
}

extension IFeeRateProvider {
    var feeRatePriorityList: [FeeRatePriority] {
        [.recommended]
    }

    var defaultFeeRatePriority: FeeRatePriority {
        .recommended
    }

    func feeRate(priority: FeeRatePriority) -> Future<Int, Never> {
        if case let .custom(value, _) = priority {
            return Future { promise in
                promise(.success(value))
            }
        } else {
            return recommendedFeeRate
        }
    }
}
