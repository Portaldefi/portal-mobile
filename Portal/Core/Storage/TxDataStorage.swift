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
    
    private func fetchTxData(txID: String) -> TxData? {
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
}

extension TxDataStorage: ITxUserDataStorage {
    func update(source: TxSource, id: String, notes: String) {
        let tx = fetch(source: source, id: id)
        tx.notes = notes
        try? context.save()
    }
    
    func update(source: TxSource, id: String, labels: [TxLabel]) {
        let tx = fetch(source: source, id: id)
        guard let data = try? JSONEncoder().encode(labels.map{ $0.label }),
        let labelsData = String(data: data, encoding: .utf8) else { return }
        tx.compressedLabels = labelsData
        try? context.save()
    }
    
    func update(source: TxSource, id: String, price: Decimal) {
        let tx = fetch(source: source, id: id)
        tx.assetUSDPrice = price as NSDecimalNumber
        try? context.save()
    }
    
    func fetch(source: TxSource, id: String) -> TxData {
        if let tx = fetchTxData(txID: id) {
            return tx
        } else {
            //Creating new instance
            let data = TxData(context: context)
            data.txID = id
            
            switch source {
            case .btcOnChain, .lightning:
                data.assetUSDPrice = marketData.lastSeenBtcPrice as NSDecimalNumber
            case .ethOnChain:
                data.assetUSDPrice = marketData.lastSeenEthPrice as NSDecimalNumber
            }
            
            context.performAndWait {
                context.insert(data)
                try? context.save()
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
}
