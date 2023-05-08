//
//  ISubmarineSwap.swift
//  Portal
//
//  Created by farid on 4/24/23.
//

import Foundation

protocol ISubmarineSwap {
    var id: String { get }
    var hash: String { get }
    var swap: Swap? { get set }
    func open() async throws
    func commit() async throws
    func cancel() async throws
}

protocol IAtomicSwap {
    var id: String { get }
    var secretHash: String { get }
    var swap: Swap? { get set }
    func open() async throws
    func commit() async throws
    func cancel() async throws
}

