//
//  WalletItem.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import Foundation
import SwiftUI

struct WalletItem: Identifiable {
    let id: UUID = UUID()
    let icon: Image
    let chainIcon: Image
    let name: String
    let description: String
    let balance: String
    let unit: String
    let value: String
}
