//
//  String+Extension.swift
//  Portal
//
//  Created by farid on 9/6/22.
//

import Foundation

extension String {
    var groupedByThree: String {
        String(
            self
                .reversed()
                .enumerated()
                .reduce(String()) {
                    $1.offset % 3 == 0 && $1.offset != 0 && $1.offset != count - 1 || $1.offset == count - 2 && self.count % 3 != 0 ? $0 + " \($1.element)" : $0 + "\($1.element)"
                }
                .reversed()
        )
    }
    
    var groupedByThreeFromLeft: String {
        self
            .enumerated()
            .reduce(String()) {
                $1.offset % 3 == 0 && $1.offset != 0 && $1.offset != count - 1 || $1.offset == count - 2 && self.count % 3 != 0 ? $0 + " \($1.element)" : $0 + "\($1.element)"
            }
    }
}
