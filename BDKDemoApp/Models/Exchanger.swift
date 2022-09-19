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
    private let coin: Coin
    private let currency: Currency
    private var subscriptions = Set<AnyCancellable>()
    
    enum Side: Int, Hashable {
        case crypto, currency
    }
        
    @Published var cryptoAmount: String = "0"
    @Published var currencyAmount: String = "0"
    @Published var isValid: Bool = true
    @Published var fee: String?

    @Published var side: Side = .crypto
    
    @Injected(Container.marketData) private var marketData
    @Injected(Container.accountViewModel) private var account
    
    private var price: Double {
        let btcPriceInUsd = marketData.btcTicker?[.usd].price ?? 1
        
        switch currency {
        case .btc:
            return btcPriceInUsd.double
        case .eth:
            return 1
        case .fiat(let fiatCurrency):
            return btcPriceInUsd.double * fiatCurrency.rate
        }
    }
    
    init(coin: Coin, currency: Currency) {
        self.coin = coin
        self.currency = currency
        
        subscribe()
    }
    
    private func subscribe() {
        $cryptoAmount
            .removeDuplicates()
            .map { Double($0) ?? 0 }
            .map { [unowned self] doubleValue -> String in
                withAnimation(.spring(response: 0.45, dampingFraction: 0.65, blendDuration: 0)) {
                    self.isValid = doubleValue <= Double(self.account.assetBalance) ?? 0
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
            .map { Double($0) ?? 0 }
            .map { [unowned self] in
                "\(($0/price).rounded(toPlaces: 6).toString())"
            }
            .sink { [unowned self] value in
                if value == "0.00" {
                    self.cryptoAmount = String()
                } else {
                    self.cryptoAmount = value
                }
                let doubleAmount = Double(self.cryptoAmount) ?? 0
                let balanceAMount = Double(self.account.assetBalance) ?? 0
                let oldValue = self.isValid
                let newValue = doubleAmount <= balanceAMount
                if oldValue != newValue {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.65, blendDuration: 0)) {
                        self.isValid = newValue
                    }
                }
            }
            .store(in: &subscriptions)
    }
    
    func sendMax() {
        
    }
}
