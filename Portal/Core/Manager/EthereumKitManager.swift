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
import Factory

class EthereumKitManager {
    private let appConfigProvider: IAppConfigProvider
    
    private(set) var signer: Signer?
    var ethereumKit: Kit?
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
                projectId: appConfigProvider.infuraCredentials.id,
                projectSecret: appConfigProvider.infuraCredentials.secret
            ),
            transactionSource: .goerliEtherscan(apiKey: appConfigProvider.etherscanKey),
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
            
            Task {
                do {
                    if let estimatedGasLimit = try await self.ethereumKit?.fetchEstimateGas(transactionData: transactionData, gasPrice: .legacy(gasPrice: gasPrice)) {
                        promise(.success(estimatedGasLimit))
                    } else {
                        promise(.success(Kit.defaultGasLimit))
                    }
                } catch {
                    promise(.success(Kit.defaultGasLimit))
                }
            }
        }
    }
    
    func gasLimit(gasPrice: Int, transactionData: TransactionData) async throws -> Int? {
        try await self.ethereumKit?.fetchEstimateGas(transactionData: transactionData, gasPrice: .legacy(gasPrice: gasPrice))
    }
}

extension EthereumKitManager {
    enum LoginError: Error {
        case seedGenerationFailed
    }
}
