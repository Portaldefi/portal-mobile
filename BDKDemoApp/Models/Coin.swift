//
//  Coin.swift
//  Portal
//
//  Created by Farid on 19.05.2020.
//  Copyright © 2020 Tides Network. All rights reserved.
//

import Foundation
import SwiftUI

struct Coin: Identifiable {
    var id: UUID = UUID()
    
    enum CoinType {
        case bitcoin
        case ethereum
        case erc20(address: String)
    }
    
    let type: CoinType
    let code: String
    let name: String
    let decimal: Int
    let icon: String
    
    var color: Color {
        switch type {
        case .bitcoin:
            return Color(red: 242/255, green: 169/255, blue: 0/255)
        case .ethereum:
            return .blue
        default:
            return .white
        }
    }
    
    init(type: CoinType, code: String, name: String, decimal: Int, iconUrl: String) {
        self.type = type
        self.code = code
        self.name = name
        self.decimal = decimal
        self.icon = iconUrl
    }
    
    static func bitcoin() -> Self {
        Coin(type: .bitcoin, code: "BTC", name: "Bitcoin", decimal: 18, iconUrl: "https://icons.iconarchive.com/icons/cjdowner/cryptocurrency-flat/96/Bitcoin-BTC-icon.png")
    }
    
    static func ethereum() -> Self {
        Coin(type: .ethereum, code: "ETH", name: "Ethereum", decimal: 18, iconUrl: "https://icons.iconarchive.com/icons/cjdowner/cryptocurrency-flat/96/Ethereum-ETH-icon.png")
    }
    
    static func portal() -> Self {
        Coin(type: .erc20(address: "0xC3Ce6148B680D0DB3AdD8504A78340AA471C4190"), code: "WHALE", name: "Portal whale token", decimal: 18, iconUrl: "https://icons.iconarchive.com/icons/cjdowner/cryptocurrency-flat/96/Ethereum-ETH-icon.png")
    }
    
    static func mocked() -> Self {
        Coin(type: .erc20(address: "0xC3Ce6148B680D0DB3AdD8504A78340AA471C4190"), code: "MOC", name: "Mock coin", decimal: 18, iconUrl: "https://icons.iconarchive.com/icons/cjdowner/cryptocurrency-flat/96/Ethereum-ETH-icon.png")
    }
}

extension Coin: Hashable {

    public static func ==(lhs: Coin, rhs: Coin) -> Bool {
        lhs.code == rhs.code && lhs.name == rhs.name
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(name)
    }

}
