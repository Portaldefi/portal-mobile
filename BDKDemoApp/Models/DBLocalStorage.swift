//
//  DBLocalStorage.swift
//  Portal
//
//  Created by Farid on 15.07.2021.
//

import Foundation
import CoreData
import Combine

final class DBlocalStorage {
    var context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
}

extension DBlocalStorage: IAccountStorage {
    var accountRecords: [AccountRecord] {
        var accountRecords: [AccountRecord] = []

        context.performAndWait {
            let request = AccountRecord.fetchRequest() as NSFetchRequest<AccountRecord>

            if let records = try? context.fetch(request) {
                accountRecords = records
            }
        }

        return accountRecords
    }
    
    func save(accountRecord: AccountRecord) {
        context.performAndWait {
            context.insert(accountRecord)
            try? context.save()
        }
    }
    
    func update(account: Account) {
        
    }
        
    func deleteAccount(_ account: Account) throws {
        if let record = accountRecords.first(where: { $0.id == account.id }) {
            context.performAndWait {
                context.delete(record)
            }
            do {
                try context.save()
            } catch {
                throw DBStorageError.cannotSaveContext(error: error)
            }
        }
    }
    
    func deleteAllAccountRecords() {
        
    }
    
    func clear() {

    }
}

enum DBError: Error {
    case missingContext
    case fetchingError
    case storingError
}

enum DBStorageError: Error {
    case cannotFetchWallets(error: Error)
    case cannotCreateWallet(error: Error)
    case cannotDeleteWallet(error: Error)
    case cannotSaveContext(error: Error)
    case cannotGetContext
}
