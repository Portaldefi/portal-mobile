//
//  Utils.swift
//  PortalTests
//
//  Created by farid on 22.11.2023.
//

import Foundation
import CryptoSwift

struct Utils {
    static func hexStringToBytes(hexString: String) -> [UInt8]? {
        let hexStr = hexString.dropFirst(hexString.hasPrefix("0x") ? 2 : 0)

        guard hexStr.count % 2 == 0 else {
            return nil
        }

        var newData = [UInt8]()

        var indexIsEven = true
        for i in hexStr.indices {
            if indexIsEven {
                let byteRange = i...hexStr.index(after: i)
                guard let byte = UInt8(hexStr[byteRange], radix: 16) else {
                    return nil
                }
                newData.append(byte)
            }
            indexIsEven.toggle()
        }
        return newData
    }

    static func bytesToHexString(bytes: [UInt8]) -> String {
        let format = "%02hhx" // "%02hhX" (uppercase)
        return bytes.map {
            String(format: format, $0)
        }
        .joined()
    }
    
    static func sha256(_ data: Data) -> Data {
        data.sha256()
    }
    
    static func createSecret() -> Data {
        var randomBytes = [UInt8](repeating: 0, count: 32)
        _ = randomBytes.withUnsafeMutableBufferPointer { bufferPointer in
            SecRandomCopyBytes(kSecRandomDefault, 32, bufferPointer.baseAddress!)
        }
        
        let secret = randomBytes
        let secretData = Data(hex: secret.toHexString())
        return secretData.sha256()
    }
}
