//
//  IMarketDataRepository.swift
//  Portal
//
//  Created by farid on 9/29/22.
//

import Foundation
import Combine
import Coinpaprika

protocol IMarketDataRepository {
    var onMarketDataUpdate: PassthroughSubject<Void, Never> { get }
    var btcTicker: TickerModel? { get }
    var ethTicker: TickerModel? { get }
    var lastSeenBtcPrice: Decimal { get }
    var lastSeenEthPrice: Decimal { get }
    var fiatCurrencies: [FiatCurrency] { get }
    func pause()
    func resume()
}
