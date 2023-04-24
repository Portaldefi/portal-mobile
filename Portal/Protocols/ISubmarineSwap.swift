//
//  ISubmarineSwap.swift
//  Portal
//
//  Created by farid on 4/24/23.
//

import Foundation

protocol ISubmarineSwap {
    var data: SwapInfo? { get }
    func open() async throws
    func commit() async throws
    func cancel() async throws
}

