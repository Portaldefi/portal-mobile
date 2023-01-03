//
//  QRCodeParser.swift
//  Portal
//
//  Created by farid on 19/8/22.
//

import Foundation
import BitcoinAddressValidator

struct QRCodeParser {
    enum ParserResults {
        case bip21, bolt11, bolt12, pubKey, privKey, unsupported
    }
    
    private(set) var parse: (String) -> [QRCodeItem]
    
    init(block: @escaping (String) -> [QRCodeItem]) {
        parse = block
    }
    
    static var current: QRCodeParser {
        QRCodeParser { code in
            QRCodeParser.parse(code: code)
        }
    }
    
    static var moc: QRCodeParser {
        QRCodeParser { code in
            [QRCodeItem.unsupported]
        }
    }
        
    static func parse(code: String) -> [QRCodeItem] {
        guard !BitcoinAddressValidator.isValid(address: code) else {
            return [QRCodeItem.bip21(address: code)]
        }

        guard
            let url = URL(string: code),
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return [QRCodeItem.unsupported]
        }

        switch components.scheme {
        case "bitcoin":
            let btcAddress = components.path

            guard let queryItems = components.queryItems else {
                if BitcoinAddressValidator.isValid(address: btcAddress) {
                    return [QRCodeItem.bip21(address: btcAddress)]
                } else {
                    return [QRCodeItem.unsupported]
                }
            }

            let amount = queryItems.first(where: {$0.name == "amount"})?.value
            let message = queryItems.first(where: {$0.name == "message"})?.value

            guard let lightningInvoice = queryItems.first(where: {$0.name == "lightning"})?.value else {
                return [QRCodeItem.bip21(address: btcAddress, amount: amount, message: message)]
            }

            return [
                QRCodeItem.bip21(address: btcAddress, amount: amount, message: message),
                QRCodeItem.bolt11(invoice: lightningInvoice)
            ]
        case "ethereum":
            let ethAddress = components.path

            guard let queryItems = components.queryItems else {
                return [QRCodeItem.eth(address: ethAddress)]
            }

            let amount = queryItems.first(where: {$0.name == "amount"})?.value
            let message = queryItems.first(where: {$0.name == "message"})?.value

            return [
                QRCodeItem.eth(address: ethAddress, amount: amount, message: message),
            ]
        default:
            if components.path.hasPrefix("xpub") {
                return [QRCodeItem.publicKey(xpub: components.path)]
            } else if components.path.hasPrefix("XP") {
                return [QRCodeItem.privateKey(key: components.path)]
            } else if components.path.hasPrefix("ln") || components.path.hasPrefix("LN") {
                return [
                    QRCodeItem.bolt11(invoice: components.path)
                ]
            } else {
                return [QRCodeItem.unsupported]
            }
        }
    }
}

