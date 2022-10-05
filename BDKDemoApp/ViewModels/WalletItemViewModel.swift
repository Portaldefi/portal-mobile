//
//  WalletItemViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 9/29/22.
//

import Foundation
import Combine
import Factory
import SwiftUI

class WalletItemViewModel: ObservableObject {
    let coin: Coin
    private let balanceAdapter: IBalanceAdapter
    private var subscriptions = Set<AnyCancellable>()
    @Injected(Container.marketData) private var marketData
    @ObservedObject private var viewState = Container.viewState()
    
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
            return "not implemented"
        }
    }
    
    init(coin: Coin, balanceAdapter: IBalanceAdapter) {
        self.coin = coin
        self.balanceAdapter = balanceAdapter
        
        self.balance = balanceAdapter.balance
        self.balanceString = "\(balanceAdapter.balance)"
        
        subscribeForUpdates()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.balance = 0.0004543223
            self.balanceString = "\(self.balance)"
            self.viewState.onAssetBalancesUpdate.send()
        }
    }
    
    private func subscribeForUpdates() {
        balanceAdapter.balanceUpdated
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.viewState.onAssetBalancesUpdate.send()
            }
            .store(in: &subscriptions)
    }
}

extension WalletItemViewModel {
    static func config(coin: Coin) -> WalletItemViewModel {
        let adapterManager = Container.adapterManager()
        guard let balanceAdapter = adapterManager.balanceAdapter(for: Wallet(coin: coin, account: Account.mocked)) else {
            fatalError("Balance adapter for \(coin) is nil")
        }
        return WalletItemViewModel(coin: coin, balanceAdapter: balanceAdapter)
    }
    
    static var mocked: WalletItemViewModel {
        WalletItemViewModel(coin: .bitcoin(), balanceAdapter: BalanceAdapterMocked())
    }
}
