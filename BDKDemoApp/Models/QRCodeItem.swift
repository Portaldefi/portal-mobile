//
//  QRCodeItem.swift
//  BDKDemoApp
//
//  Created by farid on 19/8/22.
//

import Foundation

struct QRCodeItem: Identifiable {
    enum ItemType {
        case bip21(address: String, amount: String?, message: String?),
             bolt11(invoice: String),
             bolt12(offer: String),
             pubKey(xpub: String),
             privKey(key: String),
             unsupported
    }
    
    let id = UUID()
    let type: ItemType
    
    var title: String {
        switch type {
        case .bip21:
            return "Bitcoin Address"
        case .bolt11:
            return "Bitcoin Payment Request"
        case .bolt12:
            return "Bitcoin Payment Request"
        case .pubKey:
            return "Bitcoin Public Key"
        case .privKey:
            return "Bitcoin Private Key"
        case .unsupported:
            return "Unsupported item"
        }
    }
    
    var description: String {
        switch type {
        case .bip21:
            return "Chain"
        case .bolt11:
            return "Lightning"
        case .bolt12:
            return "Lightning"
        case .pubKey:
            return "Chain"
        case .privKey:
            return "Chain"
        case .unsupported:
            return "-"
        }
    }
    
    static var unsupported: QRCodeItem {
        QRCodeItem(type: .unsupported)
    }
    
    static func bip21(address: String, amount: String? = nil, message: String? = nil) -> QRCodeItem {
        QRCodeItem(type: .bip21(address: address, amount: amount, message: message))
    }
    
    static func bolt11(invoice: String) -> QRCodeItem {
        QRCodeItem(type: .bolt11(invoice: invoice))
    }
    
    static func publicKey(xpub: String) -> QRCodeItem {
        QRCodeItem(type: .pubKey(xpub: xpub))
    }
    
    static func privateKey(key: String) -> QRCodeItem {
        QRCodeItem(type: .privKey(key: key))
    }
}
