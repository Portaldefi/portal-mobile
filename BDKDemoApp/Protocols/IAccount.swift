//
//  IAccount.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import BitcoinDevKit

protocol IAccount {
    var id: String { get }
    var index: Int { get }
    var name: String { get }
    var extendedKey: ExtendedKeyInfo { get }
}
