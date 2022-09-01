//
//  Date+Extension.swift
//  BDKDemoApp
//
//  Created by farid on 23/8/22.
//

import Foundation

extension Date {
    func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}

