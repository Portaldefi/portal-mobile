//
//  IAccountStorage.swift
//  BDKDemoApp
//
//  Created by farid on 9/19/22.
//

import Foundation

protocol IAccountStorage {
    var activeAccount: IAccount? { get }
    var allAccounts: [IAccount] { get }
    func save(account: IAccount)
    func delete(account: IAccount)
    func clear()
    func setCurrentAccount(id: String)
    func update(account: IAccount)
}
