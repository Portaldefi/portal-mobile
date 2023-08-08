//
//  SwapInfo.swift
//  Portal
//
//  Created by farid on 4/24/23.
//

import Foundation

struct Swap: Codable {
    let id: String
    let secretHash: String
    let secretHolder: Party
    let secretSeeker: Party
    let status: String
    
    private enum CodingKeys: String, CodingKey {
        case id, secretHash, secretHolder, secretSeeker, status
    }
}

struct Party: Codable {
    let id: String
    let swap: SwapId
    let asset: PAsset
    let network: AssetNetwork
    let quantity: Int64
    let state: [String: [String: InvoiceCodable]]
    let isSecretSeeker: Bool
    let isSecretHolder: Bool
    
    private enum CodingKeys: String, CodingKey {
        case id, swap, asset, network, quantity, state, isSecretSeeker, isSecretHolder
    }
}

struct SwapId: Codable {
    let id: String
}

struct PAsset: Codable {
    let name: String
    let symbol: String
    let contractAddress: String?
}

struct AssetNetwork: Codable {
    let name: String
    let type: String
    
    private enum CodingKeys: String, CodingKey {
        case name
        case type = "@type"
    }
}

struct Order: Decodable {
    let id: String
    let ts: Int64
    let uid: String
    let type: OrderType
    let side: OrderSide
    let hash: String
    let baseAsset: String
    let baseQuantity: Int32
    let baseNetwork: String
    let quoteAsset: String
    let quoteQuantity: Int64
    let quoteNetwork: String
    let status: OrderStatus
    let reason: String?
    
    enum OrderType: String, Decodable {
        case limit, market
    }

    enum OrderSide: String, Decodable {
        case ask, bid
    }
    
    enum OrderStatus: String, Decodable {
        case created, opened, commiting, commited
    }

    enum CodingKeys: String, CodingKey {
        case id, ts, uid, type, side, hash, baseAsset, baseQuantity, baseNetwork, quoteAsset, quoteQuantity, quoteNetwork, status, reason
    }
    
    init(
        id: String,
        ts: Int64,
        uid: String,
        type: OrderType,
        side: OrderSide,
        hash: String,
        baseAsset: String,
        baseQuantity: Int32,
        baseNetwork: String,
        quoteAsset: String,
        quoteQuantity: Int64,
        quoteNetwork: String,
        status: OrderStatus,
        reason: String?
    ) {
        self.id = id
        self.ts = ts
        self.uid = uid
        self.type = type
        self.side = side
        self.hash = hash
        self.baseAsset = baseAsset
        self.baseQuantity = baseQuantity
        self.baseNetwork = baseNetwork
        self.quoteAsset = quoteAsset
        self.quoteQuantity = quoteQuantity
        self.quoteNetwork = quoteNetwork
        self.status = status
        self.reason = reason
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        ts = try container.decode(Int64.self, forKey: .ts)
        uid = try container.decode(String.self, forKey: .uid)
        hash = try container.decode(String.self, forKey: .hash)
        baseAsset = try container.decode(String.self, forKey: .baseAsset)
        baseQuantity = try container.decode(Int32.self, forKey: .baseQuantity)
        baseNetwork = try container.decode(String.self, forKey: .baseNetwork)
        quoteAsset = try container.decode(String.self, forKey: .quoteAsset)
        quoteQuantity = try container.decode(Int64.self, forKey: .quoteQuantity)
        quoteNetwork = try container.decode(String.self, forKey: .quoteNetwork)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        
        let statusString = try container.decode(String.self, forKey: .status)
        guard let typeValue = OrderStatus(rawValue: statusString) else {
            throw DecodingError.dataCorruptedError(forKey: .status, in: container, debugDescription: "Invalid order status")
        }
        status = typeValue

        let typeString = try container.decode(String.self, forKey: .type)
        guard let typeValue = OrderType(rawValue: typeString) else {
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid order type")
        }
        type = typeValue

        let sideString = try container.decode(String.self, forKey: .side)
        guard let sideValue = OrderSide(rawValue: sideString) else {
            throw DecodingError.dataCorruptedError(forKey: .side, in: container, debugDescription: "Invalid swap side")
        }
        side = sideValue
    }
}

extension Order {
    static var new: Order {
        Order(
            id: String(),
            ts: 0,
            uid: String(),
            type: .limit,
            side: .ask,
            hash: String(),
            baseAsset: String(),
            baseQuantity: 0,
            baseNetwork: String(),
            quoteAsset: String(),
            quoteQuantity: 0,
            quoteNetwork: String(),
            status: .created,
            reason: nil
        )
    }
    static var mocked: Order {
        Order(
            id: "d2abad1aa3c840b18cfa2f7466c6f320",
            ts: 1683217343964,
            uid: "alice",
            type: .limit,
            side: .ask,
            hash: "a3622a913a665ca96e0b3e6c74b71072255acba7eb6eb9b71b735015b14c3538",
            baseAsset: "BTC",
            baseQuantity: 1000,
            baseNetwork: "lightning.btc",
            quoteAsset: "ETH",
            quoteQuantity: 150000000000000,
            quoteNetwork: "goerli",
            status: .created,
            reason: nil
        )
    }
}
