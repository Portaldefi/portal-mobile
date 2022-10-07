//
//  AdapterFactory.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation

class AdapterFactory: IAdapterFactory {
    func adapter(wallet: Wallet) -> IAdapter? {
        switch wallet.coin.type {
        case .bitcoin:
            do {
                return try BitcoinAdapter(wallet: wallet)
            } catch {
                print(error.localizedDescription)
                fatalError(error.localizedDescription)
            }
        default:
            return nil
        }
    }
}
