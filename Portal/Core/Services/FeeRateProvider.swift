//
//  FeeRateProvider.swift
//  Portal
//
//  Created by farid on 1/5/23.
//

import Foundation
import FeeRateKit
import Combine
import RxSwift

class FeeRateProvider {
    private let feeRateKit: FeeRateKit.Kit
    let disposeBag = DisposeBag()

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

    var ethereumGasPrice: Future<Int, Never> {
        Future { [unowned self] promise in
            self.feeRateKit.ethereum
                .subscribe(onSuccess: { price in
                    promise(.success(price))
                })
                .disposed(by: self.disposeBag)
        }
    }

    var binanceSmartChainGasPrice: Future<Int, Never> {
        Future { [unowned self] promise in
            self.feeRateKit.binanceSmartChain
                .subscribe(onSuccess: { price in
                    promise(.success(price))
                })
                .disposed(by: self.disposeBag)
        }
    }

    var litecoinFeeRate: Future<Int, Never> {
        Future { [unowned self] promise in
            self.feeRateKit.litecoin
                .subscribe(onSuccess: { price in
                    promise(.success(price))
                })
                .disposed(by: self.disposeBag)
        }
    }

    var bitcoinCashFeeRate: Future<Int, Never> {
        Future { [unowned self] promise in
            self.feeRateKit.bitcoinCash
                .subscribe(onSuccess: { price in
                    promise(.success(price))
                })
                .disposed(by: self.disposeBag)
        }
    }

    var dashFeeRate: Future<Int, Never> {
        Future { [unowned self] promise in
            self.feeRateKit.dash
                .subscribe(onSuccess: { price in
                    promise(.success(price))
                })
                .disposed(by: self.disposeBag)
        }
    }

    func bitcoinFeeRate(blockCount: Int) -> Future<Int, Never> {
        Future { [unowned self] promise in
            self.feeRateKit.bitcoin(blockCount: blockCount)
                .subscribe(onSuccess: { rate in
                    promise(.success(rate))
                })
                .disposed(by: self.disposeBag)
                
        }
    }

}

