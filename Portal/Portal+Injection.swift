//
//  Portal+Injection.swift
//  Portal
//
//  Created by farid on 25/8/22.
//

import Foundation
import Factory
import KeychainAccess
import CoreData

extension SharedContainer {
    static let accountManager = Factory<IAccountManager>(scope: .singleton) {
        let userDefaults = UserDefaults.standard
        let localStorage = LocalStorage(storage: userDefaults)
        let keychain = Keychain(service: "com.portal.keychain")
        let secureStorage = KeychainStorage(keychain: keychain)
        
        let dbContext: NSManagedObjectContext = {
            let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
            backgroundContext.automaticallyMergesChangesFromParent = true
            return backgroundContext
        }()
        
        let dbStorage = DBlocalStorage(context: dbContext)
        
        let accountStorage = AccountStorage(localStorage: localStorage, secureStorage: secureStorage, accountStorage: dbStorage)
        return AccountManager(accountStorage: accountStorage)
    }
    
    static let adapterManager = Factory<IAdapterManager>(scope: .singleton) {
        let adapterFactory = AdapterFactory()
        let walletManager = Container.walletManager()
        return AdapterManager(adapterFactory: adapterFactory, walletManager: walletManager)
    }
    
    static let walletManager = Factory<IWalletManager>(scope: .singleton) {
        let accountManager = Container.accountManager()
        let coinManager = CoinManagerMocked()
        let walletStorage = WalletStorage(coinManager: coinManager, accountManager: accountManager)
        return WalletManager(accountManager: accountManager, storage: walletStorage)
    }
    
    static let sendViewModel = Factory<SendViewViewModel>(scope: .cached) {
        SendViewViewModel.config(coin: .bitcoin())
    }
    
    static let accountViewModel = Factory<AccountViewModel>(scope: .singleton) {
        let accountManager = Container.accountManager()
        let walletManager = Container.walletManager()
        let adapterManager = Container.adapterManager()
        let userDefaults = UserDefaults.standard
        let localStorage = LocalStorage(storage: userDefaults)
        let marketData = Container.marketData()
        let viewState = Container.viewState()
        
        return AccountViewModel(
            accountManager: accountManager,
            walletManager: walletManager,
            adapterManager: adapterManager,
            localStorage: localStorage,
            marketData: marketData,
            viewState: viewState
        )
    }
    
    static let viewState = Factory<ViewState>(scope: .singleton, factory: {
        ViewState()
    })
    
    static let biometricAuthentification = Factory<BiometricAuthentication>(scope: .singleton) {
        BiometricAuthentication()
    }
    
    static let marketData = Factory<MarketData>(scope: .singleton) {
        MarketData(interval: 120, fixerApiKey: "13af1e52c56117b6c7d513603fb7cee8")
    }
}
