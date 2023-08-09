//
//  IReachabilityService.swift
//  Portal
//
//  Created by farid on 1/20/22.
//

import Foundation
import Combine

protocol IReachabilityService {
    var isReachable: CurrentValueSubject<Bool, Never> { get }
    func startMonitoring()
    func stopMonitoring()
}
