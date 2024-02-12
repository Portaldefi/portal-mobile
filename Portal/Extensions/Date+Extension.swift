//
//  Date+Extension.swift
//  Portal
//
//  Created by farid on 23/8/22.
//

import Foundation

extension Date {
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_us")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    func dateTimeFormatted() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_us")
        formatter.dateFormat = "MMM d 'at' h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter.string(from: self)
    }
    
    func extendedDate() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_us")
        formatter.dateFormat = "MMM d, yyyy HH:mm zzz"
        return formatter.string(from: self)
    }
}

