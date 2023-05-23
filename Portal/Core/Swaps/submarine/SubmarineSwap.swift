//
//  SubmarineSwap.swift
//  Portal
//
//  Created by farid on 4/21/23.
//

import Foundation
import Starscream
import Combine
import Factory

enum SwapSide {
    case secretHolder, secretSeeker
}

enum SwapError: Error {
    case invalidURL
    case invalidSocketURL
    case failedRequest(String)
    case emptyResponse
    case invalidAmount
    case swapNotExist
    case missingData
    case missingEthKit
}


class SubmarineSwap {
    private let host = "localhost"
    private let port = 64943
    
    private var client: ISubmarineSwap?
    private var side: Order.OrderSide
    private var socket: WebSocket?
    var onOrderUpdate = PassthroughSubject<Order, Never>()
    var onSwapUpdate = PassthroughSubject<Swap, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    init(side: Order.OrderSide) {
        self.side = side
        
        switch side {
        case .ask:
            
            let wallet = Container.walletManager().activeWallets.first!
            let adapter = Container.adapterManager().adapter(for: wallet)!
            
            let bitcoinKit = adapter as! ISendBitcoinAdapter
            let lightningKit = Container.lightningKitManager()
            
            client = SubmarineHolderTemplate(bitcoinKit: bitcoinKit, lightningKit: lightningKit)
        case .bid:
            
            let wallet = Container.walletManager().activeWallets.first!
            let adapter = Container.adapterManager().adapter(for: wallet)!
            
            let bitcoinKit = adapter as! IAdapter & ISendBitcoinAdapter
            let lightningKit = Container.lightningKitManager()
            
            client = SubmarineSeekerTemplate(bitcoinKit: bitcoinKit, lightningKit: lightningKit)
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
        
        if let updatedOrder = try? decoder.decode(Order.self, from: dataFromSocketString) {
            update(order: updatedOrder)
        } else if let swapUpdate = try? decoder.decode(Swap.self, from: dataFromSocketString) {
            update(swap: swapUpdate)
        }
    }
    
    private func submitLimitOrder(userId: String, side: Order.OrderSide, hash: String) async throws -> Order {
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
            "baseQuantity": 1000,
            "baseNetwork": "lightning.btc",
            "quoteAsset": "ETH",
            "quoteQuantity": 150000000000000,
            "quoteNetwork": "goerli"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        let creds = "\(userId):\(userId)"

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])

        let base64Creds = Data(creds.utf8).base64EncodedString()
        let contentType = "application/json"
        let contentLength = request.httpBody?.count ?? 0

        request.addValue(contentType, forHTTPHeaderField: "Accept")
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        request.addValue(contentType, forHTTPHeaderField: "Accept-Encoding")
        request.addValue("Basic \(base64Creds)", forHTTPHeaderField: "Authorization")
        request.addValue("identity", forHTTPHeaderField: "Content-Encoding")
        request.addValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response: \(responseString)")
            return try JSONDecoder().decode(Order.self, from: data)
        } else {
            print("No response data")
            throw SwapError.emptyResponse
        }
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
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let userId = "alice"

        let creds = "\(userId):\(userId)"

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])

        let base64Creds = Data(creds.utf8).base64EncodedString()
        let contentType = "application/json"
        let contentLength = request.httpBody?.count ?? 0

        request.addValue(contentType, forHTTPHeaderField: "Accept")
        request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        request.addValue(contentType, forHTTPHeaderField: "Accept-Encoding")
        request.addValue("Basic \(base64Creds)", forHTTPHeaderField: "Authorization")
        request.addValue("identity", forHTTPHeaderField: "Content-Encoding")
        request.addValue("\(contentLength)", forHTTPHeaderField: "Content-Length")
        
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
    
    func update(swap: Swap) {
        client?.swap = swap
        onSwapUpdate.send(swap)
    }
    
    func submitLimitOrder() async throws -> Order {
        guard let client = client else {
            fatalError("Should not happen")
        }
        
        let updatedOrder = try await submitLimitOrder(userId: client.id, side: side, hash: client.hash)
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

extension SubmarineSwap: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
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
