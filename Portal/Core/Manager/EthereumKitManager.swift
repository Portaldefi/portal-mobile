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
import Eip20Kit

class EthereumKitManager {
    private let appConfigProvider: IAppConfigProvider
    
    private(set) var signer: Signer?
    var ethereumKit: EvmKit.Kit?
    private var currentAccount: Account?

    var key: String? {
        let accountStorage = Container.accountStorage()
        let accountData = accountStorage.activeAccountRecoveryData
        
        if let data = accountData, let seed = Mnemonic.seed(mnemonic: data.words) {
            return try? Signer.privateKey(seed: seed, chain: .ethereumPlaynet).toHexString()
        }
        
        return nil
    }
    
    init(appConfigProvider: IAppConfigProvider) {
        self.appConfigProvider = appConfigProvider
    }
    
    //FIXME: fix account recovery data
    func kit(account: Account) throws -> EvmKit.Kit {
        if let ethKit = ethereumKit, let currentAccount = currentAccount, currentAccount == account {
            return ethKit
        }
        
        let accountStorage = Container.accountStorage()
        let accountData = accountStorage.activeAccountRecoveryData
        
        guard let data = accountData, let seed = Mnemonic.seed(mnemonic: data.words) else {
            throw LoginError.seedGenerationFailed
        }

        let chain = account.ethNetwork
        let rpcSource: RpcSource
        let txSource: TransactionSource
        
        switch chain {
        case .ethereumPlaynet:
            rpcSource = .portalPlaynetWebSocket(url: "ws://localhost:8545")
            txSource = .playnetDevMode(url: "http://localhost:8546")
        case .ethereumGoerli:
            rpcSource = .goerliInfuraWebsocket(
                projectId: appConfigProvider.infuraCredentials.id,
                projectSecret: appConfigProvider.infuraCredentials.secret
            )
            txSource = .goerliEtherscan(apiKey: appConfigProvider.etherscanKey)
        case .ethereumSepolia:
            rpcSource = .ethereumSepoliaHttp(projectId: appConfigProvider.infuraCredentials.id)
            txSource = .sepoliaEtherscan(apiKey: appConfigProvider.etherscanKey)
        default:
            throw LoginError.unsupportedChain
        }
        
        let address = try Signer.address(seed: seed, chain: chain)
        let signer = try Signer.instance(seed: seed, chain: chain)
        let key = try Signer.privateKey(seed: seed, chain: chain)
        
        print("Eth privKey: \(key.toHexString())")
        print("Eth pubKey: \(address.hex)")
        
        self.signer = signer
        
        let ethereumKit = try EvmKit.Kit.instance(
            address: address,
            chain: chain,
            rpcSource: rpcSource,
            transactionSource: txSource,
            walletId: account.id,
            minLogLevel: .error
        )
        
        let eip20Kit = try Eip20Kit.Kit.instance(
            evmKit: ethereumKit,
            contractAddress: address
        )
        
        // Decorators are needed to detect transactions as `Eip20` transfer/approve transactions
        Eip20Kit.Kit.addDecorators(to: ethereumKit)

        // Eip20 transactions syncer is needed to pull Eip20 transfer transactions from Etherscan
        Eip20Kit.Kit.addTransactionSyncer(to: ethereumKit)

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
        case unsupportedChain
    }
}
