//
//  IBitcoinKitManager.swift
//  Portal
//
//  Created by farid on 4/24/23.
//

import Foundation

protocol IBitcoinKitManager: IAdapter, IBalanceAdapter, IDepositAdapter, ISendBitcoinAdapter {
    var pubKey: String { get }
}
