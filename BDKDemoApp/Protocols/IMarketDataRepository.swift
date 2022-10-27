//
//  IMarketDataRepository.swift
//  BDKDemoApp
//
//  Created by farid on 9/29/22.
//

import Foundation
import Combine
import Coinpaprika

protocol IMarketDataRepository {
    var onMarketDataUpdate: PassthroughSubject<Void, Never> { get }
    var btcTicker: Ticker? { get }
    var fiatCurrencies: [FiatCurrency] { get }
    func pause()
    func resume()
}
