//
//  WalletItem.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import Foundation

struct WalletItem: Identifiable {
    let id: UUID = UUID()
    let description: String
    let balance: String
    let value: String
    
//    var fiatValue: UInt64 {
//        balance/1000
//    }
//    
//    var balanceString: String {
//        String(format: "%.8f", Double(balance) / Double(100000000))
//    }
}
