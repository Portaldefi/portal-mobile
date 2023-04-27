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
 
protocol ITxDataStorage {
    var context: NSManagedObjectContext { get }
    func fetchTxData(txID: String) -> TxData?
    func update(id: String, notes: String)
    func update(id: String, labels: [TxLable])
    func update(id: String, price: Decimal)
    func clear()
}

class TxDataStorage: ITxDataStorage {
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func update(id: String, notes: String) {
        let tx = fetchOrCreateNew(id: id)
        tx.notes = notes
        try? context.save()
    }
    
    func update(id: String, labels: [TxLable]) {
        let tx = fetchOrCreateNew(id: id)
        tx.labelsJson = "notes"
        try? context.save()
    }
    
    func update(id: String, price: Decimal) {
        let tx = fetchOrCreateNew(id: id)
        tx.txUSDPrice = price as NSDecimalNumber
        try? context.save()
    }
    
    private func fetchOrCreateNew(id: String) -> TxData {
        if let tx = fetchTxData(txID: id) {
            return tx
        } else {
            return TxData(context: context)
        }
    }
    
    func fetchTxData(txID: String) -> TxData? {
        var txData: TxData? = nil
        
        context.performAndWait {
            let fetchRequest: NSFetchRequest<TxData> = TxData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "txID == %@", txID)
            do {
                let transactionInfos = try context.fetch(fetchRequest)
                txData = transactionInfos.first
            } catch {
                print("Error fetching TransactionInfo: \(error)")
            }
        }
        
        return txData
    }
    func clear() {
        
    }
}

extension DBlocalStorage: IAccountRecordStorage {
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

extension DBlocalStorage {
    fileprivate class DBLocalStorageMock: IAccountRecordStorage {
        var context: NSManagedObjectContext {
            let managedObjectModel = NSManagedObjectModel.mergedModel(from: [Bundle.main])!
            
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
            
            do {
                try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
            } catch {
                print("Adding in-memory persistent store failed")
            }
            
            let managedObjectContext = NSManagedObjectContext.init(concurrencyType: .mainQueueConcurrencyType)
            managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
            
            return managedObjectContext
        }
        
        var accountRecords: [AccountRecord] = []
        
        func save(accountRecord: AccountRecord) {
            
        }
        
        func update(account: Account) {
            
        }
        
        func deleteAccount(_ account: Account) throws {
            
        }
        
        func deleteAllAccountRecords() {
            
        }
        
        func clear() {
            
        }
    }
    
    static var mocked: IAccountRecordStorage {
        DBLocalStorageMock()
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
