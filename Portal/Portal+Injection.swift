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
import HsToolKit

extension SharedContainer {
    static let accountManager = Factory<IAccountManager>(scope: .singleton) {
        AccountManager(accountStorage: Container.accountStorage())
    }
    
    static let notificationService = Factory<INotificationService>(scope: .singleton) {
        let accountManager = Container.accountManager()
        return NotificationService(accountManager: accountManager)
    }
    
    static let secureStorage = Factory<IKeychainStorage>(scope: .singleton) {
        let keychain = Keychain(service: "com.portal.keychain")
        return KeychainStorage(keychain: keychain)
    }
    
    static let accountStorage = Factory<IAccountStorage>(scope: .singleton) {
        let userDefaults = UserDefaults.standard
        let localStorage = LocalStorage(storage: userDefaults)
        let secureStorage = Container.secureStorage()
        
        let dbContext: NSManagedObjectContext = {
            let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
            backgroundContext.automaticallyMergesChangesFromParent = true
            return backgroundContext
        }()
        
        let dbStorage = DBlocalStorage(context: dbContext)
        
        return AccountStorage(localStorage: localStorage, secureStorage: secureStorage, accountStorage: dbStorage)
    }
    
    static let txDataStorage = Factory<ITxUserDataStorage>(scope: .singleton) {
        let dbContext: NSManagedObjectContext = {
            let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
            backgroundContext.automaticallyMergesChangesFromParent = true
            return backgroundContext
        }()
        
        let marketDataRepo = Container.marketData()
        
        return TxDataStorage(context: dbContext, marketData: marketDataRepo)
    }
        
    static let adapterManager = Factory<IAdapterManager>(scope: .singleton) {
        let appConfigProvider = Container.configProvider()
        let ethereumKitManager = Container.ethereumKitManager()
        let walletManager = Container.walletManager()
        let lightningKitManager = Container.lightningKitManager()
        let txDataStorage = Container.txDataStorage()
        let notificationService = Container.notificationService()
        
        let adapterFactory = AdapterFactory(
            appConfigProvider: appConfigProvider,
            ethereumKitManager: ethereumKitManager,
            lightningKitManager: lightningKitManager,
            txDataStorage: txDataStorage,
            notificationService: notificationService
        )
        
        return AdapterManager(adapterFactory: adapterFactory, walletManager: walletManager)
    }
    
    static let ethereumKitManager = Factory<EthereumKitManager>(scope: .singleton) {
        EthereumKitManager(appConfigProvider: Container.configProvider())
    }
    
    static let configProvider = Factory<IAppConfigProvider>(scope: .singleton) {
        AppConfigProvider()
    }
    
    static let walletManager = Factory<IWalletManager>(scope: .singleton) {
        let accountManager = Container.accountManager()
        let coinManager = Container.coinManager()
        let walletStorage = WalletStorage(coinManager: coinManager, accountManager: accountManager)
        return WalletManager(accountManager: accountManager, storage: walletStorage)
    }
    
    static let coinManager = Factory<ICoinManager>(scope: .singleton) {
        CoinManager(storage: CoinStorage(), accountManager: Container.accountManager(), userSettings: Container.settings())
    }
    
    static let lightningKitManager = Factory<ILightningKitManager>(scope: .singleton) {
        let config = Container.configProvider()
        let connectionType: ConnectionType
        
        switch config.network {
        case .playnet, .mainnet:
            let config = BitcoinCoreRpcConfig(username: "lnd", password: "lnd", port: 18443, host: "localhost")
            connectionType = .regtest(config)
        case .testnet:
            connectionType = .testnet(.blockStream)
        }
        
        return LightningKitManager(connectionType: connectionType)
    }
    
    static let sendViewModel = Factory<SendViewViewModel>(scope: .cached) {
        SendViewViewModel()
    }
    
    static let feeRateProvider = Factory<FeeRateProvider>(scope: .singleton) {
        FeeRateProvider(appConfigProvider: Container.configProvider())
    }
    
    static let reachabilityService = Factory<IReachabilityService>(scope: .singleton) {
        ReachabilityService()
    }
    
    static let bitcoinDepositAdapter = Factory<IDepositAdapter?>(scope: .shared) {
        let accountManager = Container.accountManager()
        let walletManager = Container.walletManager()
        let adapterManager = Container.adapterManager()
        
        guard let activeAccount = accountManager.activeAccount else { return nil }
        
        let wallets = walletManager.wallets(account: activeAccount)
        
        guard let btcWallet = wallets.first(where: { $0.coin == .bitcoin() }), let depositAdapter = adapterManager.depositAdapter(for: btcWallet) else { return nil }
        
        print("btc deposit adapter address: \(depositAdapter.receiveAddress)")
        
        return depositAdapter
    }
    
    static let accountViewModel = Factory<AccountViewModel>(scope: .singleton) {
        let accountManager = Container.accountManager()
        let walletManager = Container.walletManager()
        let adapterManager = Container.adapterManager()
        let userDefaults = UserDefaults.standard
        let localStorage = LocalStorage(storage: userDefaults)
        let marketData = Container.marketData()
        let settings = Container.settings()
        
        return AccountViewModel(
            accountManager: accountManager,
            walletManager: walletManager,
            adapterManager: adapterManager,
            localStorage: localStorage,
            marketData: marketData,
            settings: settings
        )
    }
    
    static let viewState = Factory<ViewState>(scope: .singleton, factory: {
        ViewState()
    })
    
    static let biometricAuthentification = Factory<BiometricAuthentication>(scope: .singleton) {
        BiometricAuthentication()
    }
    
    static let settings = Factory<IPortalSettings>(scope: .singleton) {
        PortalSettings()
    }
    
    static let pincodeViewModel = Factory<PincodeViewModel>(scope: .shared) {
        PincodeViewModel()
    }
    
    static let marketData = Factory<IMarketDataRepository>(scope: .singleton) {
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
