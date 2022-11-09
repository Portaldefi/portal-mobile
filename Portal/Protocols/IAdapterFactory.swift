//
//  IAdapterFactory.swift
//  Portal
//
//  Created by farid on 9/19/22.
//

import Foundation

protocol IAdapterFactory {
    func adapter(wallet: Wallet) -> IAdapter?
}

