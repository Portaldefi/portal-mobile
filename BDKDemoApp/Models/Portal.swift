//
//  Portal.swift
//  Portal
//
//  Created by Farid on 15.07.2021.
//

import Foundation
import KeychainAccess
import Combine
import CoreData
import SwiftUI

final class Portal {
    static let shared = Portal()
        
    private var anyCancellables: Set<AnyCancellable> = []

    private let localStorage: ILocalStorage
    private let secureStorage: IKeychainStorage
    
    let dbStorage: IAccountStorage
    let accountManager: IAccountManager
            
    private init() {
        let userDefaults = UserDefaults.standard
        
        localStorage = LocalStorage(storage: userDefaults)
        
        let keychain = Keychain(service: "com.portal.keychain")
        secureStorage = KeychainStorage(keychain: keychain)
        
        let dbContext: NSManagedObjectContext = {
            let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
            backgroundContext.automaticallyMergesChangesFromParent = true
            return backgroundContext
        }()
        
        dbStorage = DBlocalStorage(context: dbContext)
        
        if localStorage.isFirstLaunch {
            localStorage.removeCurrentAccountID()
            try? secureStorage.clear()
            dbStorage.clear()
        }
        
        localStorage.incrementAppLaunchesCouner()
                        
        let accountStorage = AccountStorage(localStorage: localStorage, secureStorage: secureStorage, accountStorage: dbStorage)
        accountManager = AccountManager(accountStorage: accountStorage)
        
//        accountManager.onActiveAccountUpdate
//            .receive(on: RunLoop.main)
//            .sink { [unowned self] account in
//                guard let activeAccount = account else  { return }
//                
//                //self.state.loading = false
//            }
//            .store(in: &anyCancellables)
    }
 
    func onTerminate() {

    }
    
    func didEnterBackground() {

    }
    
    func didBecomeActive() {

    }
}
