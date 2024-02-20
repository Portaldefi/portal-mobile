//
//  Coin.swift
//  Portal
//
//  Created by Farid on 19.05.2020.
//  Copyright © 2020 Tides Network. All rights reserved.
//

import Foundation
import SwiftUI
import PortalUI
import Factory

struct Coin: Identifiable {
    @Injected(Container.configProvider) var config
    
    enum CoinType: Equatable {
        case bitcoin
        case lightningBitcoin
        case ethereum
        case erc20(address: String)
    }
    
    let id: UUID = UUID()
    let type: CoinType
    let code: String
    let name: String
    let decimal: Int
    let icon: String
    
    var network: String {
        switch type {
        case .bitcoin:
            switch config.network {
            case .mainnet:
                return "Bitcoin"
            case .testnet:
                return "Testnet"
            case .playnet:
                return "Regtest"
            }
        case .lightningBitcoin:
            switch config.network {
            case .mainnet:
                return "Lightning"
            case .testnet:
                return "Lightning"
            case .playnet:
                return "Lightning"
            }
        case .ethereum, .erc20:
            switch config.network {
            case .mainnet:
                return "Ethereum"
            case .testnet:
                return "Sepolia"
            case .playnet:
                return "Developer"
            }
        }
    }
    
    var unit: String {
        code
    }
    
    var description: String {
        switch type {
        case .bitcoin, .ethereum, .erc20:
            return "Chain"
        case .lightningBitcoin:
            return "Lightning"
        }
    }
    
    var chainIcon: Image {
        switch type {
        case .bitcoin, .ethereum, .erc20:
            return Asset.chainIcon
        case .lightningBitcoin:
            return Asset.lightningIcon
        }
    }
    
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
    
    static func lightningBitcoin() -> Self {
        Coin(type: .lightningBitcoin, code: "BTC", name: "Bitcoin", decimal: 18, iconUrl: "https://www.prediki.com/media/displays/b866877b599146428cc7a2b9d5ce1b18/wiki_medium.png")
    }
    
    static func ethereum() -> Self {
        Coin(type: .ethereum, code: "ETH", name: "Ethereum", decimal: 18, iconUrl: "https://icons.iconarchive.com/icons/cjdowner/cryptocurrency-flat/96/Ethereum-ETH-icon.png")
    }
    
    static func portal() -> Self {
        Coin(type: .erc20(address: "0x6054237C799Ee1E61b0b4b47936E6FfF213b3ad3"), code: "XPORT", name: "Portal", decimal: 18, iconUrl: "https://i.ibb.co/s957TPr/Portal-Icon.png")
    }
    
    static func mocked() -> Self {
        Coin(type: .erc20(address: "0xC3Ce6148B680D0DB3AdD8504A78340AA471C4190"), code: "MOCK", name: "Mock coin", decimal: 18, iconUrl: "https://icons.iconarchive.com/icons/cjdowner/cryptocurrency-flat/96/Ethereum-ETH-icon.png")
    }
}

extension Coin: Hashable {
    public static func ==(lhs: Coin, rhs: Coin) -> Bool {
        lhs.code == rhs.code && lhs.name == rhs.name && lhs.unit == rhs.unit && lhs.type == rhs.type
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(code)
        hasher.combine(name)
    }
}
