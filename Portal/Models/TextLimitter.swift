//
//  TextLimitter.swift
//  Portal
//
//  Created by farid on 10/21/22.
//

import SwiftUI

class TextLimiter: ObservableObject {
    private let limit: Int
    
    init(initialText: String, limit: Int) {
        self.limit = limit
        string = initialText
        fullString = initialText
    }
    
    @Published private(set) var fullString = "0"
    @Published var string = "0" {
        didSet {
            updateFullString()
            updateString()
        }
    }
    
    private func updateFullString() {
        guard fullString.contains(string) else {
            fullString = string
            return
        }
        guard string.count < limit else { return }
        fullString = string
    }
    
    private func updateString() {
        if string.count > limit {
            string = String(fullString.prefix(limit))
        }
    }
}
