//
//  Decimal+Extension.swift
//  BDKDemoApp
//
//  Created by farid on 9/8/22.
//

import Foundation

extension Decimal {
    var double: Double {
        Double(truncating: self as NSNumber)
    }
}
