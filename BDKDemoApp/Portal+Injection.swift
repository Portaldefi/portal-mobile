//
//  Portal+Injection.swift
//  BDKDemoApp
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
    
    static let sendViewModel = Factory<SendViewViewModel>(scope: .shared) {
        SendViewViewModel()
    }
    
    static let accountViewModel = Factory<AccountViewModel>(scope: .singleton) { AccountViewModel() }
    static let viewState = Factory<ViewState>(scope: .singleton, factory: { ViewState() })
    static let biometricAuthentification = Factory<BiometricAuthentication>(scope: .singleton) {
        BiometricAuthentication()
    }
}
