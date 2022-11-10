//
//  AccountRecord+CoreDataClass.swift
//  
//
//  Created by Farid on 19.07.2021.
//
//

import Foundation
import CoreData

@objc(AccountRecord)
public class AccountRecord: NSManagedObject {    
    convenience init(id: String, index: Int, name: String, context: NSManagedObjectContext) {
        self.init(context: context)
        
        self.id = id
        self.index = Int16(index)
        self.name = name
        
        self.btcNetwork = 1 //testNet
        
        self.ethNetwork = 1 //ropsten
    }
}
