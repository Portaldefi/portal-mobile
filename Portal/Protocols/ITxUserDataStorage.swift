//
//  ITxUserDataStorage.swift
//  Portal
//
//  Created by farid on 4/28/23.
//

import Foundation
import CoreData

protocol ITxUserDataStorage {
    var context: NSManagedObjectContext { get }
    func fetch(source: TxSource, id: String) -> TxData
    func update(source: TxSource, id: String, notes: String)
    func update(source: TxSource, id: String, labels: [TxLabel])
    func update(source: TxSource, id: String, price: Decimal)
    func clear()
}
