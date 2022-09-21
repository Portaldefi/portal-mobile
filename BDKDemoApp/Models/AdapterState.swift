//
//  AdapterState.swift
//  BDKDemoApp
//
//  Created by farid on 9/19/22.
//

import Foundation

enum AdapterState: Equatable {
    case empty
    case syncing
    case synced
    case failed(Error)
    
    static func ==(lhs: AdapterState, rhs: AdapterState) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty),(.syncing, .syncing), (.synced, .synced), (.failed, .failed) : return true
        default: return false
        }
    }
}
