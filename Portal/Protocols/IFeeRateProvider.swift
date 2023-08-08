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
    
    var recommendedFeeRate: Future<Int, Never> {
        Future { promisse in
            Task {
                do {
                    let rate = try await recommendedFeeRate()
                    promisse(.success(rate))
                } catch {
                    //FIXME: - handle errors
                    promisse(.success(50))
                }
            }
        }
    }

    func feeRate(priority: FeeRatePriority) async throws -> Int {
        if case let .custom(value, _) = priority {
            return value
        } else {
            return try await recommendedFeeRate()
        }
    }
}
