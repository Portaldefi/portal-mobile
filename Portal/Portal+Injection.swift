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
import Lightning

extension SharedContainer {
    static let accountManager = Factory<IAccountManager>(scope: .singleton) {
        AccountManager(accountStorage: Container.accountStorage())
    }
    
    static let accountStorage = Factory<IAccountStorage>(scope: .singleton) {
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
        
        return AccountStorage(localStorage: localStorage, secureStorage: secureStorage, accountStorage: dbStorage)
    }
    
    static let adapterManager = Factory<IAdapterManager>(scope: .singleton) {
        let appConfigProvider = Container.configProvider()
        let ethereumKitManager = Container.ethereumKitManager()
        let adapterFactory = AdapterFactory(appConfigProvider: appConfigProvider, ethereumKitManager: ethereumKitManager)
        let walletManager = Container.walletManager()
        return AdapterManager(adapterFactory: adapterFactory, walletManager: walletManager)
    }
    
    static let ethereumKitManager = Factory<EthereumKitManager>(scope: .singleton) {
        EthereumKitManager(appConfigProvider: Container.configProvider())
    }
    
    static let configProvider = Factory<AppConfigProvider>(scope: .singleton) {
        AppConfigProvider()
    }
    
    static let walletManager = Factory<IWalletManager>(scope: .singleton) {
        let accountManager = Container.accountManager()
        let coinManager = CoinManagerMocked()
        let walletStorage = WalletStorage(coinManager: coinManager, accountManager: accountManager)
        return WalletManager(accountManager: accountManager, storage: walletStorage)
    }
    
    static let lightningKitManager = Factory<ILightningKitManager>(scope: .singleton) {
        LightningKitManager(connectionType: .testnet(.blockStream))
    }
    
    static let sendViewModel = Factory<SendViewViewModel>(scope: .cached) {
        SendViewViewModel()
    }
    
    static let feeRateProvider = Factory<FeeRateProvider>(scope: .singleton) {
        FeeRateProvider(appConfigProvider: Container.configProvider())
    }
    
    static let accountViewModel = Factory<AccountViewModel>(scope: .singleton) {
        let accountManager = Container.accountManager()
        let walletManager = Container.walletManager()
        let adapterManager = Container.adapterManager()
        let userDefaults = UserDefaults.standard
        let localStorage = LocalStorage(storage: userDefaults)
        let marketData = Container.marketData()
        
        return AccountViewModel(
            accountManager: accountManager,
            walletManager: walletManager,
            adapterManager: adapterManager,
            localStorage: localStorage,
            marketData: marketData
        )
    }
    
    static let viewState = Factory<ViewState>(scope: .singleton, factory: {
        ViewState()
    })
    
    static let biometricAuthentification = Factory<BiometricAuthentication>(scope: .singleton) {
        BiometricAuthentication()
    }
    
    static let marketData = Factory<MarketDataService>(scope: .singleton) {
        do {
            return try MarketDataService(configProvider: Container.configProvider())
        } catch {
            if let errorMessage = error as? MarketDataService.MarketDataError {
                fatalError(errorMessage.description)
            } else {
                fatalError("market data setup error")
            }
        }
    }
}
