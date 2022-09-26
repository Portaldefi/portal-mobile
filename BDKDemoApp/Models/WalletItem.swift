//
//  WalletItem.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import Foundation
import SwiftUI
import PortalUI
import Factory

struct WalletItem: Identifiable {
    let id: UUID = UUID()
    let viewModel: WalletItemViewModel
}

extension WalletItem {
    static var mockedBtc: WalletItem {
        WalletItem(viewModel: WalletItemViewModel.config(coin: .bitcoin()))
    }
}

import Combine

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
        let usdCurrency = FiatCurrency(code: "USD", name: "Dollar", rate: 1)
        switch coin.type {
        case .bitcoin:
            let usd = marketData.fiatCurrencies.first(where: { $0.code == "USD"}) ?? usdCurrency
            let btcPriceInUsd = marketData.btcTicker?[.usd].price ?? 1
            return (balance * (btcPriceInUsd/100_000_000)).double.formattedString(.fiat(usd))
        case .lightningBitcoin:
            let usd = marketData.fiatCurrencies.first(where: { $0.code == "USD"}) ?? usdCurrency
            let btcPriceInUsd = marketData.btcTicker?[.usd].price ?? 1
            return (balance * btcPriceInUsd).double.formattedString(.fiat(usd))
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
}
