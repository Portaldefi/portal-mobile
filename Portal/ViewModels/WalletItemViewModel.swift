//
//  WalletItemViewModel.swift
// Portal
//
//  Created by farid on 9/29/22.
//

import Foundation
import Combine
import Factory

class WalletItemViewModel: ObservableObject {
    let coin: Coin
    let balanceAdapter: IBalanceAdapter
    
    private var subscriptions = Set<AnyCancellable>()
    private var marketData: IMarketDataRepository
    private let updateBalanceTimer = RepeatingTimer(timeInterval: 1)
        
    private(set) var balance: Decimal
    
    @Published var balanceString = String()
    @Published var valueString = String()
    @Published var fiatCurrency = FiatCurrency(code: "USD")
    
    @Injected(Container.settings) private var settings
    
    var value: Decimal {
        switch coin.type {
        case .bitcoin, .lightningBitcoin:
            return marketData.lastSeenBtcPrice
        case .ethereum:
            return balance * marketData.lastSeenEthPrice
        case .erc20:
            return balance * marketData.lastSeenLinkPrice
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
        
        settings
            .fiatCurrency
            .receive(on: RunLoop.main)
            .sink { [weak self] currency in
                self?.fiatCurrency = currency
                self?.updateValue()
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
            _valueString = (marketData.lastSeenBtcPrice * balance * fiatCurrency.rate).double.usdFormatted()
        case .ethereum:
            _valueString = (marketData.lastSeenEthPrice * balance * fiatCurrency.rate).double.usdFormatted()
        case .erc20:
            _valueString = (marketData.lastSeenLinkPrice * balance * fiatCurrency.rate).double.usdFormatted()
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
