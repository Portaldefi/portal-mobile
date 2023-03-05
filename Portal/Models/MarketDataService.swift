//
//  MarketDataService.swift
//  Portal
//
//  Created by farid on 9/8/22.
//

import Foundation
import Combine
import Coinpaprika
import Starscream

struct TickerModel: Decodable {
    enum MessageType: String, Codable {
        case prev_close, quotes, sparkline
    }
    
    var ticker_id: String
    var prevClose: Double?
    var prev_Close: Double?
    var message_type: MessageType?
    var ts: String?
    var price: Double?
}

final class MarketDataService {
    private let btcTickerID: Any = "BTCUSD.G"
    private let ethTickerID: Any = "ETHUSD.G"
    
    private(set) var btcTicker: Ticker?
    private(set) var ethTicker: Ticker?
    private(set) var fiatCurrencies = [FiatCurrency]()
    
    private let jsonDecoder: JSONDecoder
    
    var onMarketDataUpdate = PassthroughSubject<Void, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    private var socket: WebSocket?
    
    private var socketData: [String: Any] {
        let messageTypes = ["quotes"]
        let tickers = [btcTickerID, ethTickerID].map{["ticker_id": $0, "message_types": messageTypes]}
        
        return [
            "action": "subscribe",
            "value" : [
                "tickers": tickers
            ]
        ]
    }
    
    init(jsonDecoder: JSONDecoder = JSONDecoder(), url: String, key: String) throws {
        self.jsonDecoder = jsonDecoder
        try setupSocket(url: url, key: key)
        connectSocket()
    }
    
    private func setupSocket(url: String, key: String) throws {
        guard let socketUrl = URL(string: url) else {
            throw MarketDataError.missingURL
        }
        guard let base64TokenString = key.data(using: .utf8)?.base64EncodedString() else {
            throw MarketDataError.credentialsError
        }
        
        var request = URLRequest(url: socketUrl)
        request.timeoutInterval = 5
        request.setValue("\(base64TokenString)", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        
        socket = WebSocket(request: request)
        socket?.delegate = self
    }
    
    private func connectSocket() {
        socket?.connect()
    }
    
    private func disconnectSocket() {
        socket?.disconnect()
    }
    
    private func decodeSocketString(_ string: String) {
        guard let dataFromSocketString = string.data(using: String.Encoding.utf8, allowLossyConversion: false) else { return }
        
        do {
            let results = try jsonDecoder.decode([TickerModel].self, from: dataFromSocketString)
            guard !results.isEmpty else  { return }
            print("tickers array count: \(results.count)")
        } catch {
            print("ticker decoding error: \(error)")
        }
    }
    
    deinit {
        disconnectSocket()
    }
}

extension MarketDataService: IMarketDataRepository {
    func pause() {
        //timer.suspend()
    }
    
    func resume() {
        //timer.resume()
    }
}

extension MarketDataService: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected:
            print("websocket is connected")
            do{
                let dataDict = try JSONSerialization.data(withJSONObject: socketData, options: .prettyPrinted)
                socket?.write(data: dataDict)
            } catch {
                print(error)
            }
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

extension MarketDataService {
    private class MarketDataMocked: IMarketDataRepository {
        var onMarketDataUpdate = PassthroughSubject<Void, Never>()
        var btcTicker: Ticker?
        var fiatCurrencies: [FiatCurrency] = []
        func pause() {}
        func resume() {}
    }
    
    static var mocked: IMarketDataRepository {
        MarketDataMocked()
    }
    
    enum MarketDataError: Error {
        case credentialsError
        case parametersNil
        case encodingFailed
        case missingURL
        case inconsistentBehavior
        case parsingError
        case networkError
        case error(String)
        
        var description: String {
            switch  self {
            case .parametersNil:
                return "Parameters were nil."
            case .encodingFailed:
                return "Parameter encoding failed."
            case .missingURL:
                return "URL is nil."
            case .inconsistentBehavior:
                return "Something went wrong."
            case .parsingError:
                return "Unable parse server response."
            case .networkError:
                return "Network error."
            case .credentialsError:
                return "Credentials error"
            case .error(let error):
                return error
            }
        }
        
    }
}
