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
    private let timer = RepeatingTimer(timeInterval: 1)
        
    @Published var balance: Decimal
    @Published var balanceString: String
    
    var valueString: String {
        switch coin.type {
        case .bitcoin:
            return (value*balance).double.usdFormatted()
        case .lightningBitcoin:
            return value.double.usdFormatted()
        case .ethereum, .erc20:
            return value.double.usdFormatted()
        }
    }
    
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
                
        timer.eventHandler = { [unowned self] in
            if self.balance != self.balanceAdapter.balance {
                DispatchQueue.main.async {
                    self.balance = self.balanceAdapter.balance
                    self.balanceString = "\(self.balanceAdapter.balance)"
                }
            }
        }
        
        timer.resume()
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
