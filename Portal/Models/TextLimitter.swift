//
//  TextLimitter.swift
//  Portal
//
//  Created by farid on 10/21/22.
//

import SwiftUI
import Combine

class TextLimiter: ObservableObject {
    private let limit: Int
    var updated = CurrentValueSubject<String, Never>(String())
    
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
            
            updated.send(fullString)
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
