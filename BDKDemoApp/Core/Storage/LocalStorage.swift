//
//  LocalStorage.swift
//  Portal
//
//  Created by Farid on 15.07.2021.
//

import Foundation

final class LocalStorage: ILocalStorage {
    private let storage: UserDefaults
    
    static let appLaunchesCountKey = "APP_LAUNCHES_COUNTER"
    static let currentAccountIDKey = "CURRENT_WALLET_ID"
    static let syncedExchangesIDsKey = "SYNCED_EXCHANGES_IDS"
    
    private var appLaunchesCounter: Int {
        storage.integer(forKey: Self.appLaunchesCountKey)
    }

    var currentAccountID: String?
    var isFirstLaunch: Bool {
        storage.integer(forKey: Self.appLaunchesCountKey) == 0
    }
    var syncedExchangesIds: [String] {
        storage.object(forKey: Self.syncedExchangesIDsKey) as? [String] ?? []
    }
        
    init(storage: UserDefaults) {
        self.storage = storage
    }
    
    func incrementAppLaunchesCouner() {
        let counter = appLaunchesCounter
        storage.setValue(counter + 1, forKey: Self.appLaunchesCountKey)
    }
    
    func getCurrentAccountID() -> String? {
        guard let uuidString = storage.string(forKey: Self.currentAccountIDKey) else {
            return nil
        }
        return uuidString
    }
    
    func setCurrentAccountID(_ id: String) {
        storage.setValue(id, forKey: Self.currentAccountIDKey)
    }
    
    func removeCurrentAccountID() {
        storage.removeObject(forKey: Self.currentAccountIDKey)
    }
    
    func addSyncedExchange(id: String) {
        var exchangesIds = syncedExchangesIds
        
        if !exchangesIds.contains(id) {
            exchangesIds.append(id)
            storage.set(exchangesIds, forKey: Self.syncedExchangesIDsKey)
        }
    }
    
    func removeSyncedExchange(id: String) {
        var exchangesIds = syncedExchangesIds
        
        if let index = exchangesIds.firstIndex(of: id) {
            exchangesIds.remove(at: index)
            storage.set(exchangesIds, forKey: Self.syncedExchangesIDsKey)
        }
    }
}
