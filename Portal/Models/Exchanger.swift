//
//  Exchanger.swift
//  Portal
//
//  Created by farid on 9/19/22.
//

import SwiftUI
import Combine

class Exchanger: ObservableObject {
    let base: Coin
    let quote: AccountCurrency
    let price: Decimal
    
    private var subscriptions = Set<AnyCancellable>()
        
    @Published var amount = TextLimiter(initialText: "0", limit: 10)
    
    @Published private(set) var baseAmountString = "0"
    @Published private(set) var quoteAmountString = "0"
    @Published private(set) var baseAmountDecimal: Decimal = 0
    
    private var quoteAmountDecimal: Decimal = 0
    
    @Published var side: Side = .base
        
    init(base: Coin, quote: AccountCurrency, price: Decimal) {
        self.base = base
        self.quote = quote
        self.price = price
                
        Publishers.CombineLatest(amount.updated, $side)
            .sink { [unowned self] amount, side in
                let decimalAmount = Decimal(string: amount) ?? 0
                
                if side == self.side {
                    switch side {
                    case .base:
                        self.baseAmountString = String(amount.prefix(10))
                        self.quoteAmountString = String(describing: (decimalAmount * self.price).double.rounded(toPlaces: 2))
                        self.quoteAmountDecimal = decimalAmount * self.price
                        self.baseAmountDecimal = decimalAmount
                    case .quote:
                        self.quoteAmountString = String(describing: decimalAmount.double.rounded(toPlaces: 2))
                        self.baseAmountString = String(String(describing: decimalAmount / self.price).prefix(10))
                        self.quoteAmountDecimal = decimalAmount
                        self.baseAmountDecimal = decimalAmount / self.price
                    }
                } else {
                    switch side {
                    case .base:
                        self.amount.string = String(describing: baseAmountDecimal)
                    case .quote:
                        self.amount.string = String(describing: quoteAmountDecimal)
                    }
                }
            }
            .store(in: &subscriptions)
    }
}

extension Exchanger {
    enum Side: Int, Hashable {
        case base, quote
    }
    
    static func mocked() -> Exchanger {
        let exchanger = Exchanger(base: .bitcoin(), quote: .fiat(FiatCurrency(code: "USD", name: "Dollar")), price: 21000)
        exchanger.amount.string = "0.00001"
        return exchanger
    }
}
