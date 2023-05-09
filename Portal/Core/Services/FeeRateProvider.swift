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

//    var ethereumGasPrice: Future<Int, Never> {
//        Future { [unowned self] promise in
//            self.feeRateKit.ethereum
//                .subscribe(onSuccess: { price in
//                    promise(.success(price))
//                })
//                .disposed(by: self.disposeBag)
//        }
//    }
    
    func binanceSmartChainGasPrice() async throws -> Int {
        try await feeRateKit.binanceSmartChain()
    }

//    var binanceSmartChainGasPrice: Future<Int, Never> {
//        Future { [unowned self] promise in
//            self.feeRateKit.binanceSmartChain
//                .subscribe(onSuccess: { price in
//                    promise(.success(price))
//                })
//                .disposed(by: self.disposeBag)
//        }
//    }

//    var litecoinFeeRate: Future<Int, Never> {
//        Future { [unowned self] promise in
//            self.feeRateKit.litecoin
//                .subscribe(onSuccess: { price in
//                    promise(.success(price))
//                })
//                .disposed(by: self.disposeBag)
//        }
//    }
//
//    var bitcoinCashFeeRate: Future<Int, Never> {
//        Future { [unowned self] promise in
//            self.feeRateKit.bitcoinCash
//                .subscribe(onSuccess: { price in
//                    promise(.success(price))
//                })
//                .disposed(by: self.disposeBag)
//        }
//    }
//
//    var dashFeeRate: Future<Int, Never> {
//        Future { [unowned self] promise in
//            self.feeRateKit.dash
//                .subscribe(onSuccess: { price in
//                    promise(.success(price))
//                })
//                .disposed(by: self.disposeBag)
//        }
//    }

    func bitcoinFeeRate(blockCount: Int) async throws -> Int {
        try await feeRateKit.bitcoin(blockCount: blockCount)
    }

}

