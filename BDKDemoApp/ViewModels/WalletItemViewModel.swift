//
//  WalletItemViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 9/29/22.
//

import Foundation
import Combine
import Factory

class WalletItemViewModel: ObservableObject {
    let coin: Coin
    private let balanceAdapter: IBalanceAdapter
    private var subscriptions = Set<AnyCancellable>()
    @Injected(Container.marketData) private var marketData
    
    var balance: Decimal {
        balanceAdapter.balance
    }
    
    var balanceString: String {
        "\(balance)"
    }
    
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
        subscribeForUpdates()
    }
    
    private func subscribeForUpdates() {
        balanceAdapter.balanceUpdated.sink { [weak self] in
            self?.objectWillChange.send()
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
