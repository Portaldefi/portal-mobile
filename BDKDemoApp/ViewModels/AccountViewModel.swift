//
//  AccountViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import Foundation
import Combine
import SwiftUI
import PortalUI
import Factory

class AccountViewModel: ObservableObject {
    @Published private(set) var accountName = String()
    @Published private(set) var totalBalance: String = "0"
    @Published private(set) var totalValue: String = "0"
    @Published private(set) var items: [WalletItem] = []
    @Published var selectedItem: WalletItem?
    
    private let accountManager: IAccountManager
    private let walletManager: IWalletManager
    private let adapterManager: IAdapterManager
    private let marketData: IMarketDataRepository
    
    private var subscriptions = Set<AnyCancellable>()
            
    init(
        accountManager: IAccountManager,
        walletManager: IWalletManager,
        adapterManager: IAdapterManager,
        marketData: IMarketDataRepository
    ) {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.marketData = marketData
        
        subscribeForUpdates()
    }
    
    private func subscribeForUpdates() {
        adapterManager.adapterReady
            .receive(on: DispatchQueue.global())
            .sink { [weak self] _ in
                guard let self = self else { return }
                let configuredItems = self.configuredItems()
                DispatchQueue.main.async {
                    self.items = configuredItems
                    self.updateBalance()
                    self.updateValue()
                }
            }
            .store(in: &subscriptions)
        
        marketData
            .onMarketDataUpdate
            .receive(on: RunLoop.main)
            .sink { _ in
                self.updateValue()
            }
            .store(in: &subscriptions)
    }
    
    private func updateBalance() {
        let balance = items.map{ $0.viewModel.balance }.reduce(0){ $0 + $1 }
        totalBalance = "\(balance)"
    }
    
    private func updateValue() {
        totalValue = items.first?.viewModel.valueString ?? "0"
    }
    
    private func configuredItems() -> [WalletItem] {
        walletManager.activeWallets.compactMap({ wallet in
            let coin = wallet.coin
            guard let adapter = adapterManager.balanceAdapter(for: wallet) else { return nil }
            let viewModel = WalletItemViewModel(coin: coin, balanceAdapter: adapter)
            return WalletItem(viewModel: viewModel)
        })
    }
}

extension AccountViewModel {
    static var mocked: AccountViewModel {
        let viewModel = AccountViewModel(
            accountManager: AccountManager.mocked,
            walletManager: WalletManager.mocked,
            adapterManager: AdapterManager.mocked,
            marketData: MarketData.mocked
        )
        viewModel.accountName = "Mocked"
        viewModel.totalBalance = "0.00055"
        viewModel.totalValue = "2.15"
        viewModel.items = [WalletItem.mockedBtc]
        viewModel.objectWillChange.send()
        return viewModel
    }
}
