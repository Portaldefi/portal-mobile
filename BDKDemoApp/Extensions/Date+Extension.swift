//
//  Date+Extension.swift
//  BDKDemoApp
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
}

