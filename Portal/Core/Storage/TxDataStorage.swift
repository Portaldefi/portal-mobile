//
//  TxDataStorage.swift
//  Portal
//
//  Created by farid on 4/28/23.
//

import Foundation
import CoreData

class TxDataStorage {
    private let marketData: IMarketDataRepository

    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext, marketData: IMarketDataRepository) {
        self.context = context
        self.marketData = marketData
    }
}

extension TxDataStorage: ITxUserDataStorage {
    func fetchTxData(txID: String) -> TxData? {
        var txData: TxData? = nil
        context.performAndWait {
            let fetchRequest: NSFetchRequest<TxData> = TxData.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "txID == %@", txID)
            do {
                txData = try context.fetch(fetchRequest).first
            } catch {
                print("Error fetching TransactionInfo: \(error)")
            }
        }
        return txData
    }
    
    func update(source: TxSource, id: String, notes: String) {
        context.performAndWait {
            let txData = self.fetch(source: source, id: id)
            txData.notes = notes
            saveContext()
        }
    }
    
    func update(source: TxSource, id: String, labels: [TxLabel]) {
        context.performAndWait {
            let tx = fetch(source: source, id: id)
            guard let data = try? JSONEncoder().encode(labels.map{ $0.label }),
            let labelsData = String(data: data, encoding: .utf8) else { return }
            tx.compressedLabels = labelsData
            saveContext()
        }
    }
    
    func update(source: TxSource, id: String, price: Decimal) {
        context.performAndWait {
            let tx = fetch(source: source, id: id)
            tx.assetUSDPrice = price as NSDecimalNumber
            saveContext()
        }
    }
    
    func fetch(source: TxSource, id: String) -> TxData {
        context.performAndWait {
            guard let data = fetchTxData(txID: id) else {
                //Creating new instance
                let data = TxData(context: context)
                data.txID = id
                
                switch source {
                case .btcOnChain, .lightning:
                    data.assetUSDPrice = marketData.lastSeenBtcPrice as NSDecimalNumber
                case .ethOnChain:
                    data.assetUSDPrice = marketData.lastSeenEthPrice as NSDecimalNumber
                }
                
                context.insert(data)
                
                saveContext()
                
                return data
            }
            return data
        }
    }
    
    func clear() {
        context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = TxData.fetchRequest()
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try self.context.execute(batchDeleteRequest)
                try self.context.save()
            } catch {
                print("Error clearing data: \(error)")
            }
        }
    }
    
    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
}
