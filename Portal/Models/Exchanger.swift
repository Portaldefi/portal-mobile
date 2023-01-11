//
//  Exchanger.swift
//  Portal
//
//  Created by farid on 9/19/22.
//

import SwiftUI
import Combine
import Factory

class Exchanger: ObservableObject {
    let base: Coin
    let quote: AccountCurrency
    
    private var subscriptions = Set<AnyCancellable>()
    
    enum Side: Int, Hashable {
        case base, quote
    }
        
    @Published var baseAmount = TextLimiter(limit: 10)
    @Published var quoteAmount = TextLimiter(limit: 10)
    @Published var side: Side = .base
    
    @Injected(Container.marketData) private var marketData
    
    private var price: Double {
        let btcPriceInUsd = marketData.btcTicker?[.usd].price ?? 1
        
        switch quote {
        case .btc:
            return btcPriceInUsd.double
        case .eth:
            return 1200
        case .fiat(let fiatCurrency):
            return btcPriceInUsd.double * fiatCurrency.rate
        }
    }
    
    init(base: Coin, quote: AccountCurrency) {
        self.base = base
        self.quote = quote
        
        subscribe()
    }
    
    private func subscribe() {
        baseAmount.$value
            .removeDuplicates()
            .map { Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0 }
            .map { [unowned self] doubleValue -> String in
                return "\((doubleValue * (price)).rounded(toPlaces: 2))"
            }
            .sink { [weak self] value in
                if value == "0.0" {
                    self?.quoteAmount.value = String()
                } else {
                    self?.quoteAmount.value = value
                }
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)
        
        quoteAmount.$value
            .removeDuplicates()
            .map { Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0 }
            .map { [unowned self] in
                "\(($0/price).rounded(toPlaces: 6).toString())"
            }
            .sink { [unowned self] value in
                if value == "0.00" {
                    self.baseAmount.value = String()
                } else {
                    self.baseAmount.value = value
                }
            }
            .store(in: &subscriptions)
    }
}

extension Exchanger {
    static func mocked() -> Exchanger {
        let exchanger = Exchanger(base: .bitcoin(), quote: .fiat(FiatCurrency(code: "USD", name: "Dollar")))
        exchanger.baseAmount.value = "0.00001"
        return exchanger
    }
}
