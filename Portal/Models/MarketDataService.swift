//
//  MarketDataService.swift
//  Portal
//
//  Created by farid on 9/8/22.
//

import Foundation
import Combine
import Starscream

final class MarketDataService {
    private let btcTickerID: Any = "BTCUSD.G"
    private let ethTickerID: Any = "ETHUSD.G"
    
    private(set) var btcTicker: TickerModel?
    private(set) var ethTicker: TickerModel?
    private(set) var fiatCurrencies = [FiatCurrency]()
    
    private let jsonDecoder: JSONDecoder
    private let configProvider: IAppConfigProvider
    private var socket: WebSocket?
    private let updateThreshold: TimeInterval = 60
    private var lastUpdated = Date(timeIntervalSinceNow: -3)
    private var subscriptions = Set<AnyCancellable>()
    
    var onMarketDataUpdate = PassthroughSubject<Void, Never>()
    
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
    
    init(jsonDecoder: JSONDecoder = JSONDecoder(), configProvider: IAppConfigProvider) throws {
        self.jsonDecoder = jsonDecoder
        self.configProvider = configProvider
        
        try setupSocket(url: configProvider.rafaSocketUrl, key: configProvider.rafaToken)
        connectSocket()
        
        fetchFiatCurrencies()
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
        
        if let results = try? jsonDecoder.decode([TickerModel].self, from: dataFromSocketString), !results.isEmpty {
            if btcTicker == nil || ethTicker == nil || btcTicker?.price == nil || ethTicker?.price == nil {
                if let updatedBtcTicker = results.first(where: { $0.ticker_id == btcTickerID as? String }) {
                    btcTicker = updatedBtcTicker
                    UserDefaults.standard.set(updatedBtcTicker.price, forKey: "lastSeenBtcPrice")
                }
                
                if let updatedEthTicker = results.first(where: { $0.ticker_id == ethTickerID as? String }) {
                    ethTicker = updatedEthTicker
                    UserDefaults.standard.set(updatedEthTicker.price, forKey: "lastSeenEthPrice")
                }
            } else if Date() > lastUpdated {
                if let updatedBtcTicker = results.first(where: { $0.ticker_id == btcTickerID as? String }) {
                    btcTicker = updatedBtcTicker
                    UserDefaults.standard.set(updatedBtcTicker.price, forKey: "lastSeenBtcPrice")
                }
                
                if let updatedEthTicker = results.first(where: { $0.ticker_id == ethTickerID as? String }) {
                    ethTicker = updatedEthTicker
                    UserDefaults.standard.set(updatedEthTicker.price, forKey: "lastSeenEthPrice")
                }
                
                lastUpdated = Date(timeIntervalSinceNow: updateThreshold)
                print("Send on market data update")
                onMarketDataUpdate.send(())
            }
        }
    }
    
    private func fetchFiatCurrencies() {
        let loginString = "\(configProvider.rafaUser):\(configProvider.rafaPass)"

        guard let loginData = loginString.data(using: String.Encoding.utf8), let url = URL(string: configProvider.forexUrl) else { return }
        
        let base64LoginString = loginData.base64EncodedString()
        let session = URLSession.shared
        var request = URLRequest(url: url)

        request.httpMethod = "GET"
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        
        let task = session.dataTask(with: request) { [weak self] (data, response, error) in
            guard let self = self, error == nil, let data = data else { return }
                        
            do {
                let fiatCurrenciesTickers = try self.jsonDecoder.decode([CurrencyTickerModel].self, from: data)
                
                self.fiatCurrencies = fiatCurrenciesTickers
                    .filter{ $0.ticker.contains("/USD") }
                    .compactMap{
                        guard let range = $0.ticker.range(of: "/")?.lowerBound else { return nil }
                        let code = String($0.ticker[...range].dropLast())
                        return FiatCurrency(code: code, name: code, rate: Double($0.bid) ?? 1)
                    }
            } catch {
                print(error)
            }
        }
        
        task.resume()
    }
            
    deinit {
        disconnectSocket()
    }
}

extension MarketDataService: IMarketDataRepository {
    var lastSeenBtcPrice: Decimal {
        Decimal(UserDefaults.standard.double(forKey: "lastSeenBtcPrice"))
    }
    
    var lastSeenEthPrice: Decimal {
        Decimal(UserDefaults.standard.double(forKey: "lastSeenEthPrice"))
    }
    
    func pause() {
        
    }
    
    func resume() {
        
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
        var lastSeenBtcPrice: Decimal {
            2000
        }
        
        var lastSeenEthPrice: Decimal {
            1000
        }
        
        var ethTicker: TickerModel?
        var onMarketDataUpdate = PassthroughSubject<Void, Never>()
        var btcTicker: TickerModel?
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
