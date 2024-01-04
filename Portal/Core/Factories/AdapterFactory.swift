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
    private let lightningKitManager: ILightningKitManager

    init(appConfigProvider: IAppConfigProvider, ethereumKitManager: EthereumKitManager, lightningKitManager: ILightningKitManager) {
        self.appConfigProvider = appConfigProvider
        self.ethereumKitManager = ethereumKitManager
        self.lightningKitManager = lightningKitManager
    }
    
    func adapter(wallet: Wallet) -> IAdapter? {
        switch wallet.coin.type {
        case .bitcoin:
            do {
                return try BitcoinAdapter(wallet: wallet)
            } catch {
                print("Error getting Bitcoin adapter: \(error)")
                return nil
            }
        case .lightningBitcoin:
            return LightningAdapter(wallet: wallet, manager: lightningKitManager)
        case .ethereum:
            if let ethKit = try? ethereumKitManager.kit(account: wallet.account) {
                return EthereumAdapter(evmKit: ethKit, signer: ethereumKitManager.signer)
            } else {
                return nil
            }
        case .erc20(let contractAddress):
            if let ethKit = try? ethereumKitManager.kit(account: wallet.account) {
                return try? Erc20Adapter(
                    evmKit: ethKit,
                    signer: ethereumKitManager.signer,
                    token: Erc20Token(
                        name: wallet.coin.name,
                        code: wallet.coin.code,
                        contractAddress: contractAddress,
                        decimal: wallet.coin.decimal
                    )
                )
            } else {
                return nil
            }
        }
    }
}
