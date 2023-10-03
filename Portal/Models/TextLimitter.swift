//
//  TextLimitter.swift
//  Portal
//
//  Created by farid on 10/21/22.
//

import SwiftUI
import Combine

@Observable class TextLimiter {
    private let limit: Int
    @ObservationIgnored var updated = CurrentValueSubject<String, Never>(String())
    @ObservationIgnored var stringSubject = PassthroughSubject<String, Never>()
    
    init(initialText: String, limit: Int) {
        self.limit = limit
        string = initialText
        fullString = initialText
    }
    
    private(set) var fullString = "0"
    
    var string = "0" {
        didSet {
            updateFullString()
            updateString()
            stringSubject.send(string)
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
