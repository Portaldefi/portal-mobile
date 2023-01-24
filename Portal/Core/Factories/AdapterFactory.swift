//
//  AdapterFactory.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation

class AdapterFactory: IAdapterFactory {
    private let appConfigProvider: IAppConfigProvider
    private let ethereumKitManager: EthereumKitManager

    init(appConfigProvider: IAppConfigProvider, ethereumKitManager: EthereumKitManager) {
        self.appConfigProvider = appConfigProvider
        self.ethereumKitManager = ethereumKitManager
    }
    
    func adapter(wallet: Wallet) -> IAdapter? {
        switch wallet.coin.type {
        case .bitcoin:
            do {
                return try BitcoinAdapter(wallet: wallet)
            } catch {
                print(error.localizedDescription)
                fatalError(error.localizedDescription)
            }
        case .ethereum:
            if let ethKit = try? ethereumKitManager.kit(account: wallet.account) {
                return EthereumAdapter(evmKit: ethKit, signer: ethereumKitManager.signer)
            } else {
                return nil
            }
        default:
            return nil
        }
    }
}
