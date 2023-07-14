//
//  FeeRateProvider.swift
//  Portal
//
//  Created by farid on 1/5/23.
//

import Foundation
import FeeRateKit
import Combine

class FeeRateProvider {
    private let feeRateKit: FeeRateKit.Kit

    init(appConfigProvider: IAppConfigProvider) {
        let providerConfig = FeeProviderConfig(
                ethEvmUrl: FeeProviderConfig.infuraUrl(projectId: appConfigProvider.infuraCredentials.id),
                ethEvmAuth: appConfigProvider.infuraCredentials.secret,
                bscEvmUrl: FeeProviderConfig.defaultBscEvmUrl,
                btcCoreRpcUrl: appConfigProvider.btcCoreRpcUrl,
                btcCoreRpcUser: nil,
                btcCoreRpcPassword: nil
        )
        feeRateKit = FeeRateKit.Kit.instance(providerConfig: providerConfig, minLogLevel: .error)
    }

    // Fee rates
    
    func ethereumGasPrice() async throws -> Int {
        try await feeRateKit.ethereum()
    }
    
    func binanceSmartChainGasPrice() async throws -> Int {
        try await feeRateKit.binanceSmartChain()
    }

    func bitcoinFeeRate(blockCount: Int) async throws -> Int {
        try await feeRateKit.bitcoin(blockCount: blockCount)
    }

}

