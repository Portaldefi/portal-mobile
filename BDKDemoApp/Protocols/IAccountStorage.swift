//
//  IAccountStorage.swift
//  Portal
//
//  Created by Farid on 22.07.2021.
//

import Foundation
import CoreData

protocol IAccountStorage {
    var context: NSManagedObjectContext { get }
    var accountRecords: [AccountRecord] { get }
    func save(accountRecord: AccountRecord)
    func update(account: Account)
    func deleteAccount(_ account: Account) throws
    func deleteAllAccountRecords()
    func clear()
}
