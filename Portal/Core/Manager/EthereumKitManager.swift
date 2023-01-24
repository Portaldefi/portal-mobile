//
//  EthereumKitManager.swift
//  Portal
//
//  Created by Farid on 19.07.2021.
//

import Foundation
import EvmKit
import HdWalletKit
import Combine
import RxSwift
import Factory

class EthereumKitManager {
    private let appConfigProvider: IAppConfigProvider
    private let disposeBag = DisposeBag()
    
    private(set) var signer: Signer?
    private var ethereumKit: Kit?
    private var currentAccount: Account?
    
    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }
    
    func kit(account: Account) throws -> Kit {
        if let ethKit = ethereumKit, let currentAccount = currentAccount, currentAccount == account {
            return ethKit
        }
        
        let accountStorage = Container.accountStorage()
        let accountData = accountStorage.activeAccountRecoveryData
        
        guard let data = accountData, let seed = Mnemonic.seed(mnemonic: data.words) else {
            throw LoginError.seedGenerationFailed
        }

        let chain: Chain = .ethereumGoerli
        
        let address = try Signer.address(seed: seed, chain: chain)
        let signer = try Signer.instance(seed: seed, chain: chain)
        
        self.signer = signer
        
        let ethereumKit = try Kit.instance(
            address: address,
            chain: chain,
            rpcSource: .goerliInfuraWebsocket(
                projectId: "7bffa4b191da4e9682d4351178c4736e",
                projectSecret: "5dedf9a8a4c4477687cfac3debbc23c6"
            ),
            transactionSource: .goerliEtherscan(apiKey: "PYPJHJFA2MUT12KPTT8FCKPAMGHTRDQICB"),
            walletId: account.id,
            minLogLevel: .error
        )

        ethereumKit.start()

        self.ethereumKit = ethereumKit
        currentAccount = account
        
        return ethereumKit
    }

    func gasLimit(gasPrice: Int, transactionData: TransactionData) -> Future<Int, Never> {
        Future { [weak self] promise in
            guard let self = self else { promise(.success(Kit.defaultGasLimit));  return }
                        
            self.ethereumKit?
                .estimateGas(transactionData: transactionData, gasPrice: .legacy(gasPrice: gasPrice))
                .subscribe(onSuccess: { estimatedGasLimit in
                    promise(.success(estimatedGasLimit))
                }, onError: { error in
                    promise(.success(Kit.defaultGasLimit))
                })
                .disposed(by: self.disposeBag)
        }
    }
}

extension EthereumKitManager {
    enum LoginError: Error {
        case seedGenerationFailed
    }
}
