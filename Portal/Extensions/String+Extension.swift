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
    
    var reversed: String {
        let inputStringReversed = String(self.reversed())
        let characters = Array(inputStringReversed)
        var output = String()
        
        for i in 0...characters.count - 1 {
            if i % 2 == 0 {
                if (i+1) < characters.count {
                    output.append(characters[i + 1])
                }
                output.append(characters[i])
            }
        }
        
        return output
    }
    
    func hexStringToBytes() -> [UInt8]? {
        let hexStr = self.dropFirst(self.hasPrefix("0x") ? 2 : 0)

        guard hexStr.count % 2 == 0 else { return nil }

        var newData = [UInt8]()

        var indexIsEven = true
        for i in hexStr.indices {
            if indexIsEven {
                let byteRange = i...hexStr.index(after: i)
                guard let byte = UInt8(hexStr[byteRange], radix: 16) else { return nil }
                newData.append(byte)
            }
            indexIsEven.toggle()
        }
        return newData
    }
}
