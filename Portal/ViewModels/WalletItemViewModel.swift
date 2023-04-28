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
    
    @Published var balanceString = String()
    @Published var valueString = String()
    
    var value: Decimal {
        switch coin.type {
        case .bitcoin, .lightningBitcoin:
            return marketData.lastSeenBtcPrice
        case .ethereum, .erc20:
            return balance * marketData.lastSeenEthPrice
        }
    }
    
    init(coin: Coin, balanceAdapter: IBalanceAdapter, marketData: IMarketDataRepository) {
        self.coin = coin
        self.balanceAdapter = balanceAdapter
        self.marketData = marketData
        
        self.balance = balanceAdapter.balance
        self.balanceString = "\(balanceAdapter.balance)"
                
        self.updateBalanceTimer.eventHandler = {
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
        
        updateValue()
    }
    
    private func updateBalance() {
        if balance != balanceAdapter.balance {
            balance = balanceAdapter.balance
            balanceString = "\(balanceAdapter.balance)"
            updateValue()
        }
    }
    
    private func updateValue() {
        let _valueString: String
        
        switch coin.type {
        case .bitcoin, .lightningBitcoin:
            _valueString = (marketData.lastSeenBtcPrice * balance).double.usdFormatted()
        case .ethereum, .erc20:
            _valueString = (marketData.lastSeenEthPrice * balance).double.usdFormatted()
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
