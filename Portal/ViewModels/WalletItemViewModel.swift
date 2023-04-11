//
//  WalletItemViewModel.swift
// Portal
//
//  Created by farid on 9/29/22.
//

import Foundation
import Combine
import Factory
import SwiftUI

class WalletItemViewModel: ObservableObject {
    let coin: Coin
    let balanceAdapter: IBalanceAdapter
    
    private var subscriptions = Set<AnyCancellable>()
    private var marketData: IMarketDataRepository
    private let updateBalanceTimer = RepeatingTimer(timeInterval: 1)
        
    private(set) var balance: Decimal
    
    @Published var balanceString: String
    @Published var valueString: String
    
    var value: Decimal {
        switch coin.type {
        case .bitcoin:
            return Decimal(marketData.btcTicker?.price ?? 1)
        case .lightningBitcoin:
            return Decimal(marketData.btcTicker?.price ?? 1)
        case .ethereum, .erc20:
            return (balance * 1200)
        }
    }
    
    init(coin: Coin, balanceAdapter: IBalanceAdapter, marketData: IMarketDataRepository) {
        self.coin = coin
        self.balanceAdapter = balanceAdapter
        self.marketData = marketData
        
        self.balance = balanceAdapter.balance
        self.balanceString = "\(balanceAdapter.balance)"
        self.valueString = 0.usdFormatted()
                
        self.updateBalanceTimer.eventHandler = { [unowned self] in
            DispatchQueue.main.async {
                self.updateBalance()
            }
        }
        
        self.updateBalanceTimer.resume()
        
        self
            .marketData
            .onMarketDataUpdate
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                self.updateValue()
            }
            .store(in: &subscriptions)
    }
    
    private func updateBalance() {
        if balance != balanceAdapter.balance {
            balance = balanceAdapter.balance
            balanceString = "\(balanceAdapter.balance)"
            updateValue()
        }
    }
    
    private func updateValue() {
        guard let btcUSDPrice = marketData.btcTicker?.price else { return }

        let _valueString: String
        
        switch coin.type {
        case .bitcoin, .lightningBitcoin:
            _valueString = (Decimal(btcUSDPrice) * balance).double.usdFormatted()
        case .ethereum, .erc20:
            _valueString = (Decimal(marketData.ethTicker?.price ?? 1) * balance).double.usdFormatted()
        }
        
        if valueString != _valueString {
            valueString = _valueString
        }
    }
}

extension WalletItemViewModel {
    static func config(coin: Coin) -> WalletItemViewModel {
        let adapterManager = Container.adapterManager()
        let marketData = Container.marketData()
        let walletManager = Container.walletManager()
        
        guard
            let wallet = walletManager.activeWallets.first(where: { $0.coin == coin }),
            let balanceAdapter = adapterManager.balanceAdapter(for: wallet)
        else {
            return WalletItemViewModel.mocked
        }
        return WalletItemViewModel(coin: coin, balanceAdapter: balanceAdapter, marketData: marketData)
    }
    
    static var mocked: WalletItemViewModel {
        WalletItemViewModel(
            coin: .bitcoin(),
            balanceAdapter: BalanceAdapterMocked(),
            marketData: MarketDataService.mocked
        )
    }
}
