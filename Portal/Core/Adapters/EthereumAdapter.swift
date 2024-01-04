//
//  EthereumAdapter.swift
//  Portal
//
//  Created by Farid on 10.07.2021.
//  Copyright © 2020 Tides Network. All rights reserved.
//

import Foundation
import EvmKit
import BigInt
import Combine
import Factory

//MARK: - IAdapter
class EthereumAdapter {
    private let evmKit: Kit
    private let signer: Signer?
    private let decimal = 18
    
    @Injected(Container.txDataStorage) private var txDataStorage
    @Injected(Container.notificationService) var notificationService
        
    init(evmKit: Kit, signer: Signer?) {
        self.evmKit = evmKit
        self.signer = signer
    }

    private func transactionRecord(fullTransaction: FullTransaction) -> TransactionRecord {
        let transaction = fullTransaction.transaction
        let txHash = transaction.hash.hs.hexString
        
        var isNew = false
        if txDataStorage.fetchTxData(txID: txHash) == nil { isNew = true }
                
        let type: TxType
        
        switch fullTransaction.decoration {
        case is IncomingDecoration:
            type = .received
        case is OutgoingDecoration:
            type = .sent
        default:
            type = .sent
        }
        
        var amount: Decimal?
        if let value = transaction.value, let significand = Decimal(string: value.description) {
            amount = Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }
        
        let source: TxSource = .ethOnChain
        let data = txDataStorage.fetch(source: source, id: txHash)
        let userData = TxUserData(data: data)
        
        let record = TransactionRecord(coin: .ethereum(), transaction: transaction, amount: amount, type: type, userData: userData)
        
//        if isNew {
//            guard record.type == .received else { return record }
//
//            let amount = "\(record.amount?.double ?? 0)"
//            let message = "You've received \(amount) \(record.coin.code.uppercased())"
//
//            let pNotification = PNotification(message: message)
//            notificationService.notify(pNotification)
//        }
        
        return record
    }
    
    private func convertToAdapterState(evmSyncState: SyncState) -> AdapterState {
        switch evmSyncState {
            case .synced: return .synced
            case .notSynced(let error): return .notSynced(error: error)
            case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }
}

extension EthereumAdapter: IAdapter {
    var blockchainHeight: Int32 {
        Int32(lastBlockHeight ?? 0)
    }
    
    func start() {
        evmKit.start()
    }

    func stop() {
        evmKit.stop()
    }

    func refresh() {
        evmKit.refresh()
    }

    var lastBlockHeight: Int? {
        evmKit.lastBlockHeight
    }

    var syncState: SyncState {
        evmKit.syncState
    }

    var transactionsSyncState: SyncState {
        evmKit.transactionsSyncState
    }

    var lastBlockHeightPublisher: AnyPublisher<Void, Never> {
        evmKit.lastBlockHeightPublisher.map { _ in () }.eraseToAnyPublisher()
    }

    var syncStatePublisher: AnyPublisher<Void, Never> {
        evmKit.syncStatePublisher.map { _ in () }.eraseToAnyPublisher()
    }
    
    var transactionsSyncStatePublisher: AnyPublisher<Void, Never> {
        evmKit.transactionsSyncStatePublisher.map { _ in () }.eraseToAnyPublisher()
    }
    
    var balancePublisher: AnyPublisher<Void, Never> {
        evmKit.accountStatePublisher.map { _ in () }.eraseToAnyPublisher()
    }
    
    var transactionsPublisher: AnyPublisher<Void, Never> {
        evmKit.transactionsPublisher(tagQueries: [TransactionTagQuery(protocol: .native)]).map { _ in () }.eraseToAnyPublisher()
    }

    func transactions(from hash: Data?, limit: Int?) -> [TransactionRecord] {
        evmKit.transactions(tagQueries: [TransactionTagQuery(protocol: .native)], fromHash: hash, limit: limit).compactMap { transactionRecord(fullTransaction: $0) }
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord? {
        evmKit.transaction(hash: hash).map { transactionRecord(fullTransaction: $0) }
    }

    func estimatedGasLimit(to address: EvmKit.Address, value: Decimal, gasPrice: GasPrice) async throws -> Int {
        let value = BigUInt(value.hs.roundedString(decimal: decimal))!
        return try await evmKit.fetchEstimateGas(to: address, amount: value, gasPrice: gasPrice)
    }

    func transactionSingle(hash: Data) async throws -> FullTransaction {
        try await evmKit.fetchTransaction(hash: hash)
    }

    func send(to: EvmKit.Address, amount: BigUInt, gasLimit: Int, gasPrice: GasPrice) async throws -> FullTransaction {
        guard let signer = signer else {
            throw SendError.noSigner
        }
        
        let transactionData = evmKit.transferTransactionData(to: to, value: amount)
        
        let rawTransaction = try await evmKit.fetchRawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
        let signature = try signer.signature(rawTransaction: rawTransaction)
        
        return try await evmKit.send(rawTransaction: rawTransaction, signature: signature)
    }
    
    enum SendError: Error {
        case noSigner
        case noTransaction
        case error(String)
        case unsupportedAccount
    }
}

//MARK: - IBalanceAdapter
extension EthereumAdapter: IBalanceAdapter {    
    var state: AdapterState {
        convertToAdapterState(evmSyncState: syncState)
    }
    
    var balanceStateUpdated: AnyPublisher<Void, Never> {
        syncStatePublisher
    }
    
    var balanceUpdated: AnyPublisher<Void, Never> {
        balancePublisher
    }
    
    var balance: Decimal {
        if let balance = evmKit.accountState?.balance, let significand = Decimal(string: balance.description) {
            return Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }
        return 0
    }
}

//MARK: - ITransactionsAdapter
extension EthereumAdapter: ITransactionsAdapter {
    var onTxsUpdate: AnyPublisher<Void, Never> {
        transactionsPublisher
    }
    
    var transactionRecords: [TransactionRecord] {
        transactions(from: nil, limit: nil)
    }
}

//MARK: - IDepositAdapter
extension EthereumAdapter: IDepositAdapter {
    var receiveAddress: String {
        evmKit.receiveAddress.hex
    }
}

//MARK: - ISendEthereumAdapter
extension EthereumAdapter: ISendEthereumAdapter {
    func transactionData(amount: BigUInt, address: EvmKit.Address) -> EvmKit.TransactionData {
        evmKit.transferTransactionData(to: address, value: amount)
    }
    
    func send(tx: SendETHService.Transaction) async throws -> TransactionRecord {
        let fullTransaction = try await send(
            to: tx.data.to,
            amount: tx.data.value,
            gasLimit: tx.gasData.gasLimit,
            gasPrice: .legacy(gasPrice: tx.gasData.gasPrice)
        )
        
        let record = transactionRecord(fullTransaction: fullTransaction)
        print("Eth tx sent: \(record.id) ")
        return record
    }
    
    func callSolidity(contractAddress: Address, data: Data) async throws -> Data {
        try await evmKit.fetchCall(contractAddress: contractAddress, data: data)
    }
    
    func transactionReceipt(hash: Data) async throws -> RpcTransactionReceipt {
        return try await evmKit.blockchain.transactionReceipt(transactionHash: hash)
    }
    
    func send(transactionData: TransactionData, gasLimit: Int, gasPrice: GasPrice) async throws -> FullTransaction {
        guard let signer = signer else {
            throw SendError.noSigner
        }

        let rawTransaction = try await evmKit.fetchRawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
        let signature = try signer.signature(rawTransaction: rawTransaction)

        return try await evmKit.send(rawTransaction: rawTransaction, signature: signature)
    }
}
