//
//  MarketData.swift
//  Portal
//
//  Created by farid on 9/8/22.
//

import Foundation
import Combine
import Coinpaprika

final class MarketData {
    enum NetworkError: Error {
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
            case .error(let error):
                return error
            }
        }
        
    }
    
    private(set) var btcTicker: Ticker?
    private(set) var ethTicker: Ticker?
    private(set) var fiatCurrencies = [FiatCurrency]()
    
    private let jsonDecoder: JSONDecoder
    private let timer: RepeatingTimer
    private let apiKey: String
    
    var onMarketDataUpdate = PassthroughSubject<Void, Never>()
    private var subscriptions = Set<AnyCancellable>()
    
    private var urlSession: URLSession
    
    private var latestUrl: URL? {
        URL(string: "https://data.fixer.io/api/latest?access_key=\(apiKey)&base=USD")
    }
    
    private var symbolsUrl: URL? {
        URL(string: "https://data.fixer.io/api/symbols?access_key=\(apiKey)&base=USD")
    }
    
    init(
        jsonDecoder: JSONDecoder = JSONDecoder(),
        interval: TimeInterval,
        fixerApiKey: String
    ) {
        self.jsonDecoder = jsonDecoder
        self.timer = RepeatingTimer(timeInterval: interval)
        self.apiKey = fixerApiKey
        
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        
        self.urlSession = URLSession(configuration: config)
        
        self.timer.eventHandler = { [unowned self] in
            self.updateRatesPublisher().combineLatest(self.updateSymbolsPublisher())
                .sink { (completion) in
                    if case let .failure(error) = completion {
                        print(error)
                    }
                } receiveValue: { (rates, symbols) in
                    self.fiatCurrencies = (
                        zip(
                            symbols.sorted(by: { $0.key < $1.key }),
                            rates.sorted(by: { $0.key < $1.key })
                        )
                        .map {
                            FiatCurrency(code: $0.key, name: $0.value, rate: $1.value)
                        }
                    )
                    self.onMarketDataUpdate.send()
                }
                .store(in: &self.subscriptions)

        }
        
        Coinpaprika.API.ticker(id: "btc-bitcoin", quotes: [.usd]).perform { response in
            switch response {
                case .success(let ticker):
                    self.btcTicker = ticker
                    self.onMarketDataUpdate.send()
                case .failure(let error):
                    print(error)
              }
        }
        
        Coinpaprika.API.ticker(id: "eth-ethereum", quotes: [.usd]).perform { response in
            switch response {
                case .success(let ticker):
                    self.ethTicker = ticker
                    self.onMarketDataUpdate.send()
                case .failure(let error):
                    print(error)
              }
        }
        
        self.timer.resume()
    }
    
    private func updateRatesPublisher() -> Future<Rates, NetworkError> {
        Future<Rates, NetworkError> { [unowned self] promise in
            guard let url = latestUrl else {
                return promise(.failure(.inconsistentBehavior))
            }
            urlSession.dataTaskPublisher(for: url)
                .tryMap { $0.data }
                .decode(type: FiatRatesResponse.self, decoder: jsonDecoder)
                .sink { (completion) in
                    if case let .failure(error) = completion {
                        promise(.failure(.error(error.localizedDescription)))
                    }
                } receiveValue: { response in
                    if response.success, let rates = response.rates {
                        promise(.success(rates))
                    } else {
                        promise(.failure(.networkError))
                    }
                }
                .store(in: &subscriptions)

        }
    }
    
    private func updateSymbolsPublisher() -> Future<[String : String], NetworkError> {
        Future<[String : String], NetworkError> { [unowned self] promise in
            guard let url = symbolsUrl else {
                return promise(.failure(.inconsistentBehavior))
            }
            urlSession.dataTaskPublisher(for: url)
                .tryMap { $0.data }
                .decode(type: FiatSymbols.self, decoder: jsonDecoder)
                .sink { (completion) in
                    if case let .failure(error) = completion {
                        promise(.failure(.error(error.localizedDescription)))
                    }
                } receiveValue: { (response) in
                    if response.success, let symbols = response.symbols {
                        promise(.success(symbols))
                    } else {
                        promise(.failure(.networkError))
                    }
                }
                .store(in: &subscriptions)
        }
    }
}

extension MarketData: IMarketDataRepository {
    func pause() {
        timer.suspend()
    }
    
    func resume() {
        timer.resume()
    }
}

extension MarketData {
    static var mocked: IMarketDataRepository {
        MarketDataMoked()
    }
    private class MarketDataMoked: IMarketDataRepository {
        var onMarketDataUpdate = PassthroughSubject<Void, Never>()
        var btcTicker: Ticker?
        var fiatCurrencies: [FiatCurrency] = []
        func pause() {}
        func resume() {}
    }
}
