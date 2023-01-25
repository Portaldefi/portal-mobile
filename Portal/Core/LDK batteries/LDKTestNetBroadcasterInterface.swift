//
//  LDKTestNetBroadcasterInterface.swift
//  Portal
//
//  Created by farid on 6/13/22.
//

import Foundation
import Alamofire
import LightningDevKit

class LDKTestNetBroadcasterInterface: BroadcasterInterface {
    private static let url = "https://blockstream.info/testnet/api/tx"
        
    override func broadcastTransaction(tx: [UInt8]) {
        print("TX TO BROADCAST: \(tx.toHexString())")
        
        var request = try! URLRequest(url: LDKTestNetBroadcasterInterface.url, method: .post, headers: ["Content-Type": "text/plain"])
        request.httpBody = tx.toHexString().data(using: .utf8)
        
        AF.request(request).responseString { response in
            switch (response.result) {
            case .success(let txId):
                print("txID: \(txId)")
            case .failure(let error):
                print(error)
            }
        }
    }
}

//extension Data {
//    func hexEncodedString(options: HexEncodingOptions = []) -> String {
//        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
//        return map {
//            String(format: format, $0)
//        }.joined()
//    }
//
//    struct HexEncodingOptions: OptionSet {
//        let rawValue: Int
//        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
//    }
//}
