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

struct Erc20Token {
    let name: String
    let code: String
    let contractAddress: String
    let decimal: Int
    
    var coin: Coin {
        Coin(
            type: .erc20(address: contractAddress),
            code: code,
            name: name,
            decimal: decimal,
            iconUrl: "https://icons.iconarchive.com/icons/cjdowner/cryptocurrency-flat/96/Ethereum-ETH-icon.png"
        )
    }
}

class Erc20Adapter {
    private let evmKit: EvmKit.Kit
    private let signer: Signer?
    private let notificationService: INotificationService
    private let txDataStorage: ITxUserDataStorage
    private let eip20Kit: Eip20Kit.Kit
    private let token: Erc20Token
    private var cancellable: AnyCancellable?

    init(evmKit: EvmKit.Kit, signer: Signer?, token: Erc20Token, txDataStorage: ITxUserDataStorage, notificationService: INotificationService) throws {
        self.evmKit = evmKit
        self.signer = signer
        self.token = token
        self.txDataStorage = txDataStorage
        self.notificationService = notificationService
        
        let contractAddress = try Address(hex: token.contractAddress)
        
        eip20Kit = try Eip20Kit.Kit.instance(evmKit: evmKit, contractAddress: contractAddress)
        subscribeForBalanceUpdates()
    }
    
    private func subscribeForBalanceUpdates() {
        cancellable = onTxsUpdate.sink { [unowned self] _ in
            updateLastKnowTxTimestamp()
        }
    }
    
    private func updateLastKnowTxTimestamp() {
        for transaction in transactionRecords {
            switch transaction {
            case let record as EvmTransactionRecord:
                guard
                    lastKnownTxTimestamp > 0,
                    let timestamp = transaction.timestamp,
                    case .received(let coin) = transaction.type,
                    timestamp > lastKnownTxTimestamp
                else { continue }
                                                
                let amount = (record.amount ?? 0).formatted()
                let message = "You've received \(amount) \(coin.code.uppercased())"
                
                notificationService.sendLocalNotification(
                    title: "Received \(coin.code.uppercased())",
                    body: message
                )
            default:
                continue
            }
        }
        
        if
            let mostRecentTxTimestamp = transactionRecords.compactMap({ $0.timestamp }).max(),
            mostRecentTxTimestamp > lastKnownTxTimestamp
        {
            UserDefaults.standard.setValue(mostRecentTxTimestamp, forKey: "lastKnownTxTimestamp.eth.erc-20.\(token.code)")
        }
    }

    private func transactionRecord(fromTransaction fullTransaction: FullTransaction) -> TransactionRecord {
        let transaction = fullTransaction.transaction
                
        let data = txDataStorage.fetch(source: .erc20(token: token), id: transaction.hash.hs.hexString)
        let userData = TxUserData(data: data)
        
        var type: TxType = .unknown
        
        switch fullTransaction.decoration {
        case is IncomingDecoration:
            type = .received(coin: token.coin)
        case is OutgoingDecoration:
            type = .sent(coin: token.coin)
        case let decoration as UnknownTransactionDecoration:
            let address = evmKit.address
//            let internalTransactions = decoration.internalTransactions.filter { $0.to == address }
            let transferEventInstances = decoration.eventInstances.compactMap { $0 as? TransferEventInstance }
            let incomingTransfers = transferEventInstances.filter { $0.to == address && $0.from != address }
            let outgoingTransfers = transferEventInstances.filter { $0.from == address }
            
            var amount: Decimal?
            
            if let transfer = incomingTransfers.first, incomingTransfers.count == 1 {
                type = .received(coin: token.coin)
                
                if let significand = Decimal(string: transfer.value.description) {
                    amount = Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
                }
                
                let record = EvmTransactionRecord(
                    coin: token.coin,
                    transaction: transaction,
                    type: type,
                    amount: amount,
                    sender: transfer.from.eip55,
                    receiver: transfer.to.eip55,
                    userData: userData
                )
                
//                if isNew {
//                    let amount = "\(record.amount?.double ?? 0)"
//                    let message = "You've received \(amount) \(record.coin.code.uppercased())"
//
//                    let pNotification = PNotification(message: message)
//                    notificationService.notify(pNotification)
//                }
                
                return record
            } else if let transfer = outgoingTransfers.first, outgoingTransfers.count == 1 {
                type = .sent(coin: token.coin)
                
                if let significand = Decimal(string: transfer.value.description) {
                    amount = Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
                }
                
                return EvmTransactionRecord(coin: token.coin, transaction: transaction, type: type, amount: amount, sender: transfer.from.eip55, receiver: transfer.to.eip55, userData: userData)
            }
        case let decoration as OutgoingEip20Decoration:
            type = .sent(coin: token.coin)
                        
            var amount: Decimal?
            
            if let significand = Decimal(string: decoration.value.description) {
                amount = Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
            }
            
            let record = EvmTransactionRecord(
                coin: token.coin,
                transaction: transaction,
                type: type,
                amount: amount,
                sender: evmKit.address.eip55,
                receiver: decoration.to.eip55,
                userData: userData
            )

            return record
        case is ApproveEip20Decoration:
            type = .sent(coin: token.coin)

        default:
            type = .unknown
        }

        var amount: Decimal?

        if let value = transaction.value, let significand = Decimal(string: value.description) {
            amount = Decimal(sign: .plus, exponent: -token.decimal, significand: significand)
        }
        
        let record = EvmTransactionRecord(coin: token.coin, transaction: transaction, type: type, amount: amount, sender: transaction.from?.eip55, receiver: transaction.to?.eip55, userData: userData)
        
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
    var lastKnownTxTimestamp: Int {
        UserDefaults.standard.integer(forKey: "knownTxTimestamp.eth.erc-20.\(token.code)")
    }
    
    var onTxsUpdate: AnyPublisher<Void, Never> {
        balancePublisher
    }
    
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
    
    func send(transaction: SendETHService.Transaction) async throws -> TransactionRecord {
        let txData = transaction.data
        let gasLimit = transaction.gasData.gasLimit
        let gasPrice: GasPrice = .legacy(gasPrice: transaction.gasData.gasPrice)
        
        let fullTransaction = try await send(transactionData: txData, gasLimit: gasLimit, gasPrice: gasPrice)
        
        let record = transactionRecord(fromTransaction: fullTransaction)
        print("\(token.code) tx sent: \(record.id) ")
        return record
    }
    
    func callSolidity(contractAddress: EvmKit.Address, data: Data) async throws -> Data {
        Data()
    }
    
    func transactionReceipt(hash: Data) async throws -> EvmKit.RpcTransactionReceipt {
        throw SendError.noSigner
    }
    
    func send(transactionData: EvmKit.TransactionData, gasLimit: Int, gasPrice: EvmKit.GasPrice) async throws -> EvmKit.FullTransaction {
        guard let signer = signer else {
            throw SendError.noSigner
        }

        let rawTransaction = try await evmKit.fetchRawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
        let signature = try signer.signature(rawTransaction: rawTransaction)

        return try await evmKit.send(rawTransaction: rawTransaction, signature: signature)
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
        eip20Kit.transactions(from: hash, limit: limit).compactMap { transactionRecord(fromTransaction: $0) }
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord? {
        nil
    }

    func estimatedGasLimit(to address: Address, value: Decimal, gasPrice: GasPrice) async throws -> Int {
        let value = BigUInt(value.hs.roundedString(decimal: token.decimal))!
        let transactionData = transactionData(amount: value, address: address)

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
}

extension Erc20Adapter {

    enum SendError: Error {
        case noSigner
    }

}
