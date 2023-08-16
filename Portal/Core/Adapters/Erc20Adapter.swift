//
//  Erc20Adapter.swift
//  Portal
//
//  Created by farid on 31.05.2023.
//

import Foundation
import Combine
import BigInt
import EvmKit
import Eip20Kit
import HsExtensions
import Factory

struct Erc20Token {
    let name: String
    let code: String
    let contractAddress: String
    let decimal: Int
}

class Erc20Adapter {
    private let evmKit: EvmKit.Kit
    private let signer: Signer?
    private let eip20Kit: Eip20Kit.Kit
    private let token: Erc20Token
    
    @Injected(Container.notificationService) var notificationService
    @Injected(Container.txDataStorage) private var txDataStorage

    init(evmKit: EvmKit.Kit, signer: Signer?, token: Erc20Token) throws {
        self.evmKit = evmKit
        self.signer = signer
        self.token = token
        
        let contractAddress = try Address(hex: token.contractAddress)
        
        eip20Kit = try Eip20Kit.Kit.instance(evmKit: evmKit, contractAddress: contractAddress)
    }

    private func transactionRecord(fromTransaction fullTransaction: FullTransaction) -> TransactionRecord? {
        let transaction = fullTransaction.transaction
        
        var isNew = false
        if txDataStorage.fetchTxData(txID: transaction.hash.toHexString()) == nil { isNew = true }
        
        var type: TxType = .unknown
        
        let source: TxSource = .ethOnChain
        let data = txDataStorage.fetch(source: source, id: transaction.hash.toHexString())
        let userData = TxUserData(data: data)
        
        switch fullTransaction.decoration {
        case is IncomingDecoration:
            type = .received
        case is OutgoingDecoration:
            type = .sent
        case let decoration as UnknownTransactionDecoration:
            let address = evmKit.address
            let internalTransactions = decoration.internalTransactions.filter { $0.to == address }
            let transferEventInstances = decoration.eventInstances.compactMap { $0 as? TransferEventInstance }
            let incomingTransfers = transferEventInstances.filter { $0.to == address && $0.from != address }
            let outgoingTransfers = transferEventInstances.filter { $0.from == address }
            
            var amount: Decimal?
            
            if let transfer = incomingTransfers.first, incomingTransfers.count == 1 {
                type = .received
                
                if let significand = Decimal(string: transfer.value.description) {
                    amount = Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
                }
                
                let record = TransactionRecord(token: token, transaction: transaction, amount: amount, type: type, from: transfer.from.eip55, to: transfer.to.eip55, userData: userData)
                
                if isNew {
                    let amount = "\(record.amount?.double ?? 0)"
                    let message = "You've received \(amount) \(record.coin.code.uppercased())"

                    let pNotification = PNotification(message: message)
                    notificationService.notify(pNotification)
                }
                
                return record
            } else if let transfer = outgoingTransfers.first, outgoingTransfers.count == 1 {
                type = .sent
                
                if let significand = Decimal(string: transfer.value.description) {
                    amount = Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
                }
                
                return TransactionRecord(token: token, transaction: transaction, amount: amount, type: type, from: transfer.from.eip55, to: transfer.to.eip55, userData: userData)
            }
        case is OutgoingEip20Decoration:
            type = .sent

        case is ApproveEip20Decoration:
            type = .sent

        default:
            type = .unknown
        }

        var amount: Decimal?

        if let value = transaction.value, let significand = Decimal(string: value.description) {
            amount = Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
        }
        
        let record =  TransactionRecord(token: token, transaction: transaction, amount: amount, type: type, from: transaction.from?.eip55, to: transaction.to?.eip55, userData: userData)
        
        if isNew {
            guard record.type == .received else { return record }

            let amount = "\(record.amount?.double ?? 0)"
            let message = "You've received \(amount) \(record.coin.code.uppercased())"

            let pNotification = PNotification(message: message)
            notificationService.notify(pNotification)
        }
                
        return record
    }
}

extension Erc20Adapter: IAdapter {
    var blockchainHeight: Int32 {
        Int32(evmKit.lastBlockHeight ?? 0)
    }
    
    func start() {
        
    }
    
    func stop() {
        
    }
    
    func refresh() {
       
    }
}

extension Erc20Adapter: IBalanceAdapter {
    var L1Balance: Decimal {
        balance
    }
    
    var state: AdapterState {
        convertToAdapterState(evmSyncState: eip20Kit.syncState)
    }
    
    var balanceStateUpdated: AnyPublisher<Void, Never> {
        syncStatePublisher
    }
    
    var balanceUpdated: AnyPublisher<Void, Never> {
        balancePublisher
    }
    
    func convertToAdapterState(evmSyncState: EvmKit.SyncState) -> AdapterState {
        switch evmSyncState {
            case .synced: return .synced
            case .notSynced(let error): return .notSynced(error: error)
            case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }
}

extension Erc20Adapter: ITransactionsAdapter {    
    var transactionRecords: [TransactionRecord] {
        transactions(from: nil, limit: nil)
    }
}

extension Erc20Adapter: IDepositAdapter {
    var receiveAddress: String {
        evmKit.receiveAddress.eip55
    }
}

extension Erc20Adapter: ISendEthereumAdapter {
    func transactionData(amount: BigUInt, address: EvmKit.Address) -> EvmKit.TransactionData {
        eip20Kit.transferTransactionData(to: address, value: amount)
    }
    
    func send(tx: SendETHService.Transaction) async throws -> TransactionRecord {
        .mocked(confirmed: true)
    }
    
    func callSolidity(contractAddress: EvmKit.Address, data: Data) async throws -> Data {
        Data()
    }
    
    func transactionReceipt(hash: Data) async throws -> EvmKit.RpcTransactionReceipt {
        throw SendError.noSigner
    }
    
    func send(transactionData: EvmKit.TransactionData, gasLimit: Int, gasPrice: EvmKit.GasPrice) async throws -> EvmKit.FullTransaction {
        throw SendError.noSigner
    }
}

extension Erc20Adapter {
    var name: String {
        token.name
    }

    var coin: String {
        token.code
    }

    var lastBlockHeight: Int? {
        evmKit.lastBlockHeight
    }

    var syncState: EvmKit.SyncState {
        switch eip20Kit.syncState {
        case .synced: return EvmKit.SyncState.synced
        case .syncing: return EvmKit.SyncState.syncing(progress: nil)
        case .notSynced(let error): return EvmKit.SyncState.notSynced(error: error)
        }
    }

    var transactionsSyncState: EvmKit.SyncState {
        switch eip20Kit.transactionsSyncState {
        case .synced: return EvmKit.SyncState.synced
        case .syncing: return EvmKit.SyncState.syncing(progress: nil)
        case .notSynced(let error): return EvmKit.SyncState.notSynced(error: error)
        }
    }

    var balance: Decimal {
        if let balance = eip20Kit.balance, let significand = Decimal(string: balance.description) {
            return Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
        }

        return 0
    }

    var lastBlockHeightPublisher: AnyPublisher<Void, Never> {
        evmKit.lastBlockHeightPublisher.map { _ in () }.eraseToAnyPublisher()
    }

    var syncStatePublisher: AnyPublisher<Void, Never> {
        eip20Kit.syncStatePublisher.map { _ in () }.eraseToAnyPublisher()
    }

    var transactionsSyncStatePublisher: AnyPublisher<Void, Never> {
        eip20Kit.transactionsSyncStatePublisher.map { _ in () }.eraseToAnyPublisher()
    }

    var balancePublisher: AnyPublisher<Void, Never> {
        eip20Kit.balancePublisher.map { _ in () }.eraseToAnyPublisher()
    }

    var transactionsPublisher: AnyPublisher<Void, Never> {
        eip20Kit.transactionsPublisher.map { _ in () }.eraseToAnyPublisher()
    }

    func transactions(from hash: Data?, limit: Int?) -> [TransactionRecord] {
        eip20Kit.transactions(from: hash, limit: limit)
                .compactMap {
                    transactionRecord(fromTransaction: $0)
                }
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord? {
        nil
    }

    func estimatedGasLimit(to address: Address, value: Decimal, gasPrice: GasPrice) async throws -> Int {
        let value = BigUInt(value.hs.roundedString(decimal: token.decimal))!
        let transactionData = eip20Kit.transferTransactionData(to: address, value: value)

        return try await evmKit.fetchEstimateGas(transactionData: transactionData, gasPrice: gasPrice)
    }

    func fetchTransaction(hash: Data) async throws -> FullTransaction {
        try await evmKit.fetchTransaction(hash: hash)
    }

    func allowance(spenderAddress: Address) async throws -> Decimal {
        let allowanceString = try await eip20Kit.allowance(spenderAddress: spenderAddress)

        guard let significand = Decimal(string: allowanceString) else {
            return 0
        }

        return Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
    }

    func send(to: Address, amount: Decimal, gasLimit: Int, gasPrice: GasPrice) async throws {
        guard let signer = signer else {
            throw SendError.noSigner
        }

        let value = BigUInt(amount.hs.roundedString(decimal: token.decimal))!
        let transactionData = eip20Kit.transferTransactionData(to: to, value: value)

        let rawTransaction = try await evmKit.fetchRawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
        let signature = try signer.signature(rawTransaction: rawTransaction)

        _ = try await evmKit.send(rawTransaction: rawTransaction, signature: signature)
    }

}

extension Erc20Adapter {

    enum SendError: Error {
        case noSigner
    }

}
