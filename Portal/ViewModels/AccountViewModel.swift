//
//  AccountViewModel.swift
// Portal
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
    private let localStorage: ILocalStorage
    
    private var subscriptions = Set<AnyCancellable>()
    
    @ObservedObject private var viewState: ViewState
    
    var accountDataIsBackedUp: Bool {
        localStorage.isAccountBackedUp
    }
            
    init(
        accountManager: IAccountManager,
        walletManager: IWalletManager,
        adapterManager: IAdapterManager,
        localStorage: ILocalStorage,
        marketData: IMarketDataRepository,
        viewState: ViewState
    ) {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.localStorage = localStorage
        self.marketData = marketData
        self.viewState = viewState
        
        subscribeForUpdates()
    }
    
    private func subscribeForUpdates() {
        adapterManager.adapterReady
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.items = self.configuredItems()
            }
            .store(in: &subscriptions)
        
        marketData
            .onMarketDataUpdate
            .receive(on: RunLoop.main)
            .sink { _ in
                self.updateValue()
            }
            .store(in: &subscriptions)
        
        if let account = accountManager.activeAccount {
            accountName = account.name
        }
        
        accountManager.onActiveAccountUpdate.sink { [weak self] account in
            guard let account = account else { return }
            self?.accountName = account.name
        }
        .store(in: &subscriptions)
        
        $items
            .delay(for: .seconds(0.1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateBalance()
                self?.updateValue()
            }
            .store(in: &subscriptions)
        
        viewState.onAssetBalancesUpdate
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateBalance()
                self?.updateValue()
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
        walletManager.activeWallets.compactMap{ WalletItem(coin: $0.coin) }
    }
}

extension AccountViewModel {
    static var mocked: AccountViewModel {
        let viewModel = AccountViewModel(
            accountManager: AccountManager.mocked,
            walletManager: WalletManager.mocked,
            adapterManager: AdapterManager.mocked,
            localStorage: LocalStorage.mocked,
            marketData: MarketData.mocked,
            viewState: ViewState()
        )
        viewModel.accountName = "Mocked"
        viewModel.totalBalance = "0.00055"
        viewModel.totalValue = "2.15"
        viewModel.items = [WalletItem.mockedBtc]
        viewModel.objectWillChange.send()
        return viewModel
    }
}
