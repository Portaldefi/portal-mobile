//
//  TextLimitter.swift
//  BDKDemoApp
//
//  Created by farid on 10/21/22.
//

import SwiftUI

class TextLimiter: ObservableObject {
    private let limit: Int
    
    init(limit: Int) {
        self.limit = limit
    }
    
    @Published var value = "0" {
        didSet {
            if value.count > limit {
                value = String(value.prefix(limit))
                hasReachedLimit = true
            } else {
                hasReachedLimit = false
            }
        }
    }
    @Published var hasReachedLimit = false
}
