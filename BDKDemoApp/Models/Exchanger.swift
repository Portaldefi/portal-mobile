//
//  Exchanger.swift
//  BDKDemoApp
//
//  Created by farid on 9/19/22.
//

import SwiftUI
import Combine
import Factory

class Exchanger: ObservableObject {
    private let balanceAdapter: IBalanceAdapter
    private let base: Coin
    private let quote: AccountCurrency
    private var subscriptions = Set<AnyCancellable>()
    
    enum Side: Int, Hashable {
        case crypto, currency
    }
        
    @Published var cryptoAmount: String = "0"
    @Published var currencyAmount: String = "0"
    @Published var amountIsValid: Bool = true

    @Published var side: Side = .crypto
    
    @Injected(Container.marketData) private var marketData
    
    private var price: Double {
        let btcPriceInUsd = marketData.btcTicker?[.usd].price ?? 1
        
        switch quote {
        case .btc:
            return btcPriceInUsd.double
        case .eth:
            return 1
        case .fiat(let fiatCurrency):
            return btcPriceInUsd.double * fiatCurrency.rate
        }
    }
    
    init(base: Coin, quote: AccountCurrency, balanceAdapter: IBalanceAdapter) {
        self.base = base
        self.quote = quote
        self.balanceAdapter = balanceAdapter
        
        subscribe()
    }
    
    private func subscribe() {
        $cryptoAmount
            .removeDuplicates()
            .map { Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0 }
            .map { [unowned self] doubleValue -> String in
                withAnimation(.spring(response: 0.45, dampingFraction: 0.65, blendDuration: 0)) {
                    self.amountIsValid = doubleValue <= self.balanceAdapter.balance.double
                }
                return "\((doubleValue * (price)).rounded(toPlaces: 2))"
            }
            .sink { [weak self] value in
                if value == "0.0" {
                    self?.currencyAmount = String()
                } else {
                    self?.currencyAmount = value
                }
                
            }
            .store(in: &subscriptions)
        
        $currencyAmount
            .removeDuplicates()
            .map { Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0 }
            .map { [unowned self] in
                "\(($0/price).rounded(toPlaces: 6).toString())"
            }
            .sink { [unowned self] value in
                if value == "0.00" {
                    self.cryptoAmount = String()
                } else {
                    self.cryptoAmount = value
                }
            }
            .store(in: &subscriptions)
    }
}
