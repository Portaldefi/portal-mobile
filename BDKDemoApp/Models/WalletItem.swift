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
    let balance: Int64
    
    var fiatValue: Int64 {
        balance/1000
    }
}
