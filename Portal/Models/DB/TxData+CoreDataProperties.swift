//
//  TxData+CoreDataProperties.swift
//  Portal
//
//  Created by farid on 4/28/23.
//
//

import Foundation
import CoreData


extension TxData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TxData> {
        return NSFetchRequest<TxData>(entityName: "TxData")
    }

    @NSManaged public var txID: String
    @NSManaged public var notes: String
    @NSManaged public var compressedLabels: String
    @NSManaged public var assetUSDPrice: NSDecimalNumber
    
    var labels: [TxLabel] {
        let data = Data(compressedLabels.utf8)
        let strings = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        return strings.map { TxLabel(label: $0) }
    }
}

extension TxData : Identifiable {
    
}
