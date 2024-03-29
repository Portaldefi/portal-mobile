//
//  File.swift
//  
//
//  Created by farid on 05.01.2024.
//

class Utils {
    static func bytesToHex32Reversed(bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)) -> String
    {
        var bytesArray: [UInt8] = []
        bytesArray.append(bytes.0)
        bytesArray.append(bytes.1)
        bytesArray.append(bytes.2)
        bytesArray.append(bytes.3)
        bytesArray.append(bytes.4)
        bytesArray.append(bytes.5)
        bytesArray.append(bytes.6)
        bytesArray.append(bytes.7)
        bytesArray.append(bytes.8)
        bytesArray.append(bytes.9)
        bytesArray.append(bytes.10)
        bytesArray.append(bytes.11)
        bytesArray.append(bytes.12)
        bytesArray.append(bytes.13)
        bytesArray.append(bytes.14)
        bytesArray.append(bytes.15)
        bytesArray.append(bytes.16)
        bytesArray.append(bytes.17)
        bytesArray.append(bytes.18)
        bytesArray.append(bytes.19)
        bytesArray.append(bytes.20)
        bytesArray.append(bytes.21)
        bytesArray.append(bytes.22)
        bytesArray.append(bytes.23)
        bytesArray.append(bytes.24)
        bytesArray.append(bytes.25)
        bytesArray.append(bytes.26)
        bytesArray.append(bytes.27)
        bytesArray.append(bytes.28)
        bytesArray.append(bytes.29)
        bytesArray.append(bytes.30)
        bytesArray.append(bytes.31)
        
        return Utils.bytesToHex(bytes: bytesArray.reversed())
    }
    
    static func arrayToTuple32(array: [UInt8]) -> (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) {
        return (array[0], array[1], array[2], array[3], array[4], array[5], array[6], array[7], array[8], array[9], array[10], array[11], array[12], array[13], array[14], array[15], array[16], array[17], array[18], array[19], array[20], array[21], array[22], array[23], array[24], array[25], array[26], array[27], array[28], array[29], array[30], array[31])
    }
    
    static func bytesToHex(bytes: [UInt8]) -> String
    {
        var hexString: String = ""
        var count = bytes.count
        for byte in bytes
        {
            hexString.append(String(format:"%02X", byte))
            count = count - 1
        }
        return hexString.lowercased()
    }
    
    static func hexStringToByteArray(_ hexString: String) -> [UInt8] {
        let length = hexString.count
        if length & 1 != 0 {
            return []
        }
        var bytes = [UInt8]()
        bytes.reserveCapacity(length/2)
        var index = hexString.startIndex
        for _ in 0..<length/2 {
            let nextIndex = hexString.index(index, offsetBy: 2)
            if let b = UInt8(hexString[index..<nextIndex], radix: 16) {
                bytes.append(b)
            } else {
                return []
            }
            index = nextIndex
        }
        return bytes
    }
    
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
}
