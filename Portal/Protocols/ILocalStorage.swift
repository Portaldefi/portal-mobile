//
//  ILocalStorage.swift
//  Portal
//
//  Created by Farid on 15.07.2021.
//

import Foundation

protocol ILocalStorage {
    var syncedExchangesIds: [String] { get }
    var isFirstLaunch: Bool { get }
    var currentAccountID: String? { get set }
    var isAccountBackedUp: Bool { get }
    func incrementAppLaunchesCouner()
    func getCurrentAccountID() -> String?
    func setCurrentAccountID(_ id: String)
    func removeCurrentAccountID()
    func addSyncedExchange(id: String)
    func removeSyncedExchange(id: String)
    func markAccountIsBackeUp()
}
