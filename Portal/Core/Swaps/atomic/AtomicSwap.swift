//
//  AtomicSwap.swift
//  Portal
//
//  Created by farid on 5/5/23.
//

import Foundation
import Starscream
import Combine
import Factory
import BigInt
import PortalSwapSDK

class AtomicSwap {
    private let host = "localhost"
    private let port = 64943
    
    private var client: IAtomicSwap?
    private var side: Order.OrderSide
    private var socket: WebSocket?
    private var subscriptions = Set<AnyCancellable>()
    
    var onOrderUpdate = PassthroughSubject<Order, Never>()
    var onSwapUpdate = PassthroughSubject<SwapModel, Never>()
        
    init(side: Order.OrderSide) {
        self.side = side
        
        switch side {
        case .ask:
            let wallet = Container.walletManager().activeWallets.last!
            let adapter = Container.adapterManager().adapter(for: wallet)!
            
            let ethereumKit = adapter as! ISendEthereumAdapter
            let lightningKit = Container.lightningKitManager()
            
            client = AtomicHolderTemplate(ethereumKit: ethereumKit, lightningKit: lightningKit)
        case .bid:
            let wallet = Container.walletManager().activeWallets.last!
            let adapter = Container.adapterManager().adapter(for: wallet)!
            
            let ethereumKit = adapter as! IAdapter & ISendEthereumAdapter
            let lightningKit = Container.lightningKitManager()
            
            client = AtomicSeekerTemplate(ethereumKit: ethereumKit, lightningKit: lightningKit)
        }
        
        socket = try? configureSocket()
        socket?.delegate = self
        socket?.connect()
    }
        
    deinit { disconnectSocket() }
    
    private func configureSocket() throws -> WebSocket? {
        guard let client = client else { return nil }
        
        let path = "api/v1/updates/\(client.id)"
        
        guard let socketUrl = URL(string: "ws://\(host):\(port)/\(path)") else {
            return nil
        }
        
        var request = URLRequest(url: socketUrl)
        request.timeoutInterval = 5
        
        return WebSocket(request: request)
    }
    
    private func connectSocket() {
        socket?.connect()
    }
    
    private func disconnectSocket() {
        socket?.disconnect()
    }
    
    private func decodeSocketString(_ string: String) {
        print("Soket data string: \(string)")
        
        guard let dataFromSocketString = string.data(using: String.Encoding.utf8, allowLossyConversion: false) else { return }
        
        let decoder = JSONDecoder()
        
//        if let updatedOrder = try? decoder.decode(Order.self, from: dataFromSocketString) {
//            update(order: updatedOrder)
//        } else if let swapUpdate = try? decoder.decode(Swap.self, from: dataFromSocketString) {
//            update(swap: swapUpdate)
//        }
    }
    
    private func submitLimitOrder(userId: String, side: Order.OrderSide, hash: String, baseQuantity: Decimal, quoteQuantity: Decimal) async throws -> Order {
        let urlString = "http://\(host):\(port)/api/v1/orderbook/limit"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            throw SwapError.invalidURL
        }

        let requestBody: [String: Any] = [
            "uid": userId,
            "side": side.rawValue,
            "hash": hash,
            "baseAsset": "BTC",
            "baseQuantity": 10000,
            "baseNetwork": "lightning.btc",
            "quoteAsset": "ETH",
            "quoteQuantity": 100000,
            "quoteNetwork": "goerli"
        ]
        
        let request = try buildRequest(url: url, method: "PUT", userId: userId, body: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response: \(responseString)")
            return try JSONDecoder().decode(Order.self, from: data)
        } else {
            print("No response data")
            throw SwapError.emptyResponse
        }
    }
    
    private func buildRequest(url: URL, method: String, userId: String, body: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method

        let creds = "\(userId):\(userId)"

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let base64Creds = Data(creds.utf8).base64EncodedString()
        let contentType = "application/json"
        let contentLength = request.httpBody?.count ?? 0

        request.addValue(contentType, forHTTPHeaderField: "Accept")
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        request.addValue(contentType, forHTTPHeaderField: "Accept-Encoding")
        request.addValue("Basic \(base64Creds)", forHTTPHeaderField: "Authorization")
        request.addValue("identity", forHTTPHeaderField: "Content-Encoding")
        request.addValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
        
        return request
    }
    
    private func removeLimitOrder() async throws -> Order {
        let urlString = "http://\(host):\(port)/api/v1/orderbook/limit"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            throw SwapError.invalidURL
        }
        
        let orderId = "580b1a1c19314aa2b9efba44c205d76a"

        let requestBody: [String: Any] = [
            "id": orderId,
            "baseAsset": "BTC",
            "quoteAsset": "ETH"
        ]
        
        let request = try buildRequest(url: url, method: "DELETE", userId: "alice", body: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response: \(responseString)")
            return try JSONDecoder().decode(Order.self, from: data)
        } else {
            print("No response data")
            throw SwapError.emptyResponse
        }
    }
    
    func update(order: Order) {
        onOrderUpdate.send(order)
    }
    
    func update(swap: SwapModel) {
        client?.swap = swap
        onSwapUpdate.send(swap)
    }
    
    func submitLimitOrder(baseQuantity: String, quoteQuantity: String) async throws -> Order {
        guard let client = client else {
            fatalError("Should not happen")
        }
        
        guard let baseQuantityDecimal = Decimal(string: baseQuantity),
              let quoteQuantityDecimal = Decimal(string: quoteQuantity) else {
            throw SwapError.invalidAmount
        }
        
        let sats = baseQuantityDecimal * 100000000
        let wei = quoteQuantityDecimal * 1000000000000000000
        
        let satsString = String(describing: sats)
        print(satsString)
        let weiString = String(describing: wei)
        print(weiString)
        
        let updatedOrder = try await submitLimitOrder(
            userId: client.id,
            side: side,
            hash: client.secretHash,
            baseQuantity: sats,
            quoteQuantity: wei
        
        )
        update(order: updatedOrder)
        
        return updatedOrder
    }
    
    func open() async throws {
        try await client?.open()
    }
    
    func commit() async throws {
        try await client?.commit()
    }
    
    func cancel() async throws {
        try await client?.cancel()
    }
}

extension AtomicSwap: WebSocketDelegate {
    func didReceive(event: Starscream.WebSocketEvent, client: Starscream.WebSocket) {
        switch event {
        case .connected:
            print("websocket is connected")
        case .disconnected(let reason, let code):
            print("websocket is disconnected: \(reason) with code: \(code)")
        case .text(let string):
            decodeSocketString(string)
        case .cancelled:
            print("Cancelled")
        case .error(let error):
            print(error ?? "Error")
        default:
            break
        }
    }
}
