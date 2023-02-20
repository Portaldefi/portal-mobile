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
        
    @Published var balance: Decimal
    @Published var balanceString: String
    
    var valueString: String {
        switch coin.type {
        case .bitcoin:
            let btcPriceInUsd = marketData.btcTicker?[.usd].price ?? 1
            return (balance * btcPriceInUsd).double.usdFormatted()
        case .lightningBitcoin:
            let btcPriceInUsd = marketData.btcTicker?[.usd].price ?? 1
            return (balance * btcPriceInUsd).double.usdFormatted()
        case .ethereum, .erc20:
            return (balance * 1200).double.usdFormatted()
        }
    }
    
    init(coin: Coin, balanceAdapter: IBalanceAdapter, marketData: IMarketDataRepository) {
        self.coin = coin
        self.balanceAdapter = balanceAdapter
        self.marketData = marketData
        
        self.balance = balanceAdapter.balance
        self.balanceString = "\(balanceAdapter.balance)"
        
        subscribeForUpdates()
    }
    
    private func subscribeForUpdates() {
        balanceAdapter.balanceUpdated
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self = self else { return }
                self.balance = self.balanceAdapter.balance
                self.balanceString = "\(self.balanceAdapter.balance)"
            }
            .store(in: &subscriptions)
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
            marketData: MarketData.mocked
        )
    }
}
