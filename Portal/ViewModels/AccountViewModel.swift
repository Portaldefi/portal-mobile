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

@Observable class AccountViewModel {
    private(set) var accountName = String()
    private(set) var totalBalance: String = "0"
    private(set) var totalValue: String = "0"
    
    private(set) var fiatCurrency = FiatCurrency(code: "USD")
    private(set) var portolioCurrency = Coin.bitcoin()
    
    private(set) var items: [WalletItem] = [] {
        didSet {
            updateValues()
            
            Publishers.Sequence(sequence: items)
                .flatMap { $0.balanceUpdated }
                .receive(on: RunLoop.main)
                .print("Update balance values")
                .sink { [unowned self] _ in
                    self.updateValues()
                }
                .store(in: &subscriptions)
        }
    }
    
    public var selectedItem: WalletItem?
    public var goToSend = false {
        willSet {
            if newValue != goToSend && newValue == false {
                Container.Scope.cached.reset()
            }
        }
    }
    public var goToReceive = false
    public var goToSettings = false
    public var goToLightningChannelSetup = false
    public var goToLightningChannelAwaits = false
    
    @ObservationIgnored private let accountManager: IAccountManager
    @ObservationIgnored private let walletManager: IWalletManager
    @ObservationIgnored private let adapterManager: IAdapterManager
    @ObservationIgnored private let marketData: IMarketDataRepository
    @ObservationIgnored private let localStorage: ILocalStorage
    @ObservationIgnored private let settings: IPortalSettings
    
    @ObservationIgnored private var subscriptions = Set<AnyCancellable>()
        
    var accountDataIsBackedUp: Bool {
        localStorage.isAccountBackedUp
    }
    
    var hasUsableLightningChannel: Bool {
        guard let adapter = adapterManager.adapter(for: .lightningBitcoin()) as? ILightningChannels else {
            return false
        }
        
        return !adapter.usableChannels.isEmpty
    }
    
    var hasLightningChannel: Bool {
        guard let adapter = adapterManager.adapter(for: .lightningBitcoin()) as? ILightningChannels else {
            return false
        }
        
        return adapter.channelBalance > 0
    }
            
    init(
        accountManager: IAccountManager,
        walletManager: IWalletManager,
        adapterManager: IAdapterManager,
        localStorage: ILocalStorage,
        marketData: IMarketDataRepository,
        settings: IPortalSettings
    ) {
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.adapterManager = adapterManager
        self.localStorage = localStorage
        self.marketData = marketData
        self.settings = settings
        
        subscribeForUpdates()
        
//        if let account = accountManager.activeAccount {
//            accountName = account.name
//        }
    }
        
    private func subscribeForUpdates() {
        adapterManager.adapterReady
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.items = self.configuredItems()
            }
            .store(in: &subscriptions)
        
        marketData
            .onMarketDataUpdate
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                self.updateValues()
            }
            .store(in: &subscriptions)
        
        accountManager
            .onActiveAccountUpdate
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] account in
                self?.accountName = account.name
            }
            .store(in: &subscriptions)
        
        settings
            .fiatCurrency
            .receive(on: RunLoop.main)
            .sink { [weak self] currency in
                self?.fiatCurrency = currency
                self?.updateValues()
            }
            .store(in: &subscriptions)
        
        settings
            .portfolioCurrency
            .receive(on: RunLoop.main)
            .sink { [weak self] currency in
                self?.portolioCurrency = currency
                self?.updateValues()
            }
            .store(in: &subscriptions)
    }
    
    func updateValues() {
        guard !self.goToSend && !self.goToReceive && !self.goToSettings && !self.goToLightningChannelSetup else { return }

        updateBalance()
        updateValue()
    }
    
//    func updatePortfolioCurrency() {
//        if portolioCurrency == .bitcoin() {
//            portolioCurrency = .ethereum()
//        } else {
//            portolioCurrency = .bitcoin()
//        }
//        
//        updateBalance()
//    }
    
    private func convertToBtcBalance(item: WalletItem) -> Decimal {
        switch item.coin.type {
        case .bitcoin, .lightningBitcoin:
            return item.viewModel.balance
        case .ethereum:
            return (item.viewModel.balance * marketData.lastSeenEthPrice) / marketData.lastSeenBtcPrice
        case .erc20:
            //FIX ME
            return (item.viewModel.balance * 1.2) / marketData.lastSeenBtcPrice
        }
    }
    
    private func convertToEthBalance(item: WalletItem) -> Decimal {
        switch item.coin.type {
        case .bitcoin, .lightningBitcoin:
            return (item.viewModel.balance * marketData.lastSeenBtcPrice) / marketData.lastSeenEthPrice
        case .ethereum:
            return item.viewModel.balance
        case .erc20:
            //FIX ME
            return (item.viewModel.balance * marketData.lastSeenLinkPrice) / marketData.lastSeenEthPrice
        }
    }
    
    private func convertToPortfolioBalance(item: WalletItem) -> Decimal {
        switch portolioCurrency.type {
        case .bitcoin:
            return convertToBtcBalance(item: item)
        case .ethereum:
            return convertToEthBalance(item: item)
        default:
            return 0
        }
    }
        
    private func updateBalance() {        
        let balance = items.map{ convertToPortfolioBalance(item: $0) }.reduce(0){ $0 + $1 }.double.rounded(toPlaces: 12)
        
        if totalBalance != "\(balance)" {
            DispatchQueue.main.async {
                self.totalBalance = "\(balance)"
            }
        }
    }
    
    private func updateValue() {
        let value = items
            .map{ convertToBtcBalance(item: $0) * marketData.lastSeenBtcPrice * fiatCurrency.rate }
            .reduce(0, { $0 + $1 })
            .double
            .formattedString(.fiat(fiatCurrency))
        
        if value != "NaN" && totalValue != value {
            DispatchQueue.main.async {
                self.totalValue = value
            }
        }
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
            marketData: MarketDataService.mocked,
            settings: MockedPortalSettings()
        )
        viewModel.accountName = "Mocked"
        viewModel.totalBalance = "0.00055"
        viewModel.totalValue = "2.15"
        viewModel.items = [WalletItem.mockedBtc]
//        viewModel.objectWillChange.send()
        
        return viewModel
    }
}
