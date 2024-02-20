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
    private let txDataStorage: ITxUserDataStorage
    private let notificationService: INotificationService

    init(
        appConfigProvider: IAppConfigProvider,
        ethereumKitManager: EthereumKitManager,
        lightningKitManager: ILightningKitManager,
        txDataStorage: ITxUserDataStorage,
        notificationService: INotificationService
    ) {
        self.appConfigProvider = appConfigProvider
        self.ethereumKitManager = ethereumKitManager
        self.lightningKitManager = lightningKitManager
        self.txDataStorage = txDataStorage
        self.notificationService = notificationService
    }
    
    func adapter(wallet: Wallet) throws -> IAdapter {
        switch wallet.coin.type {
        case .bitcoin:
            return try BitcoinAdapter(
                wallet: wallet,
                txDataStorage: txDataStorage,
                notificationService: notificationService
            )
        case .lightningBitcoin:
            return LightningAdapter(
                wallet: wallet,
                manager: lightningKitManager,
                txDataStorage: txDataStorage, 
                notificationService: notificationService
            )
        case .ethereum:
            let ethKit = try ethereumKitManager.kit(account: wallet.account)
            
            return EthereumAdapter(
                evmKit: ethKit,
                signer: ethereumKitManager.signer,
                txDataStorage: txDataStorage,
                notificationService: notificationService
            )
        case .erc20(let contractAddress):
            let ethKit = try ethereumKitManager.kit(account: wallet.account)
                
            let token = Erc20Token(
                name: wallet.coin.name,
                code: wallet.coin.code,
                contractAddress: contractAddress,
                decimal: wallet.coin.decimal
            )
            
            return try Erc20Adapter(
                evmKit: ethKit,
                signer: ethereumKitManager.signer,
                token: token,
                txDataStorage: txDataStorage,
                notificationService: notificationService
            )
        }
    }
}
