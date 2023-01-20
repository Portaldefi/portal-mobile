//
//  EthereumAdapter.swift
//  Portal
//
//  Created by Farid on 10.07.2021.
//  Copyright © 2020 Tides Network. All rights reserved.
//

import Foundation
import EvmKit
import RxSwift
import BigInt
import Combine


//MARK: - IAdapter
class EthereumAdapter: IAdapter {
    var blockchainHeight: Int32 = 0
    
    private let evmKit: Kit
    private let signer: Signer?
    private let decimal = 18
    
    private let disposeBag = DisposeBag()
    
    init(evmKit: Kit, signer: Signer?) {
        self.evmKit = evmKit
        self.signer = signer
    }

    private func transactionRecord(fullTransaction: FullTransaction) -> TransactionRecord {
        let transaction = fullTransaction.transaction
        var amount: Decimal?
        if let value = transaction.value, let significand = Decimal(string: value.description) {
            amount = Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }
        
        let type: TxType
        
        if transaction.to?.hex == receiveAddress {
            type = .received
        } else {
            type = .sent
        }
        
        return TransactionRecord(coin: .ethereum(), transaction: transaction, amount: amount, type: type)
    }
    
    private func convertToAdapterState(evmSyncState: SyncState) -> AdapterState {
        switch evmSyncState {
            case .synced: return .synced
            case .notSynced(let error): return .notSynced(error: error)
            case .syncing: return .syncing(progress: 50, lastBlockDate: nil)
        }
    }
}

extension EthereumAdapter {
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

    var lastBlockHeightObservable: Observable<Void> {
        evmKit.lastBlockHeightObservable.map { _ in () }
    }

    var syncStateObservable: Observable<Void> {
        evmKit.syncStateObservable.map { _ in () }
    }

    var transactionsSyncStateObservable: Observable<Void> {
        evmKit.transactionsSyncStateObservable.map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        evmKit.accountStateObservable.map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        evmKit.transactionsObservable(tagQueries: []).map { _ in () }
    }

    func transactionsSingle(from hash: Data?, limit: Int?) -> Future<[TransactionRecord], Never> {
        Future { [weak self] promise in
            let disposeBag = DisposeBag()
            
            self?.evmKit.transactionsSingle(tagQueries: [], fromHash: hash, limit: limit)
                    .map { [weak self] in
                        $0.compactMap {
                            self?.transactionRecord(fullTransaction: $0)
                        }
                    }
                    .subscribe(onSuccess: { records in
                        promise(.success(records))
                    })
                    .disposed(by: disposeBag)
        }
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord? {
        evmKit.transaction(hash: hash).map { transactionRecord(fullTransaction: $0) }
    }

    func estimatedGasLimit(to address: EvmKit.Address, value: Decimal, gasPrice: GasPrice) -> Single<Int> {
        let value = BigUInt(value.hs.roundedString(decimal: decimal))!

        return evmKit.estimateGas(to: address, amount: value, gasPrice: gasPrice)
    }

    func transactionSingle(hash: Data) -> Single<FullTransaction> {
        evmKit.transactionSingle(hash: hash)
    }

    func sendSingle(to: EvmKit.Address, amount: BigUInt, gasLimit: Int, gasPrice: GasPrice) -> Single<FullTransaction> {
        guard let signer = signer else {
            return Single.error(SendError.noSigner)
        }

        let transactionData = evmKit.transferTransactionData(to: to, value: amount)

        return evmKit.rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
                .flatMap { [weak self] rawTransaction in
                    guard let strongSelf = self else {
                        throw Kit.KitError.weakReference
                    }

                    let signature = try signer.signature(rawTransaction: rawTransaction)

                    return strongSelf.evmKit.sendSingle(rawTransaction: rawTransaction, signature: signature)
                }
                .map { (tx: FullTransaction) in tx }
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
        syncStateObservable.map { _ in() }.publisher.catch { _ in Just(()) }.eraseToAnyPublisher()
    }
    
    var balanceUpdated: AnyPublisher<Void, Never> {
        evmKit.accountStateObservable.map { _ in() }.publisher.catch { _ in Just(()) }.eraseToAnyPublisher()
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
    var transactionRecords: AnyPublisher<[TransactionRecord], Never> {
        transactionsSingle(from: nil, limit: nil).eraseToAnyPublisher()
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
    
    func send(tx: SendETHService.Transaction) -> Future<TransactionRecord, Error> {
        Future { promise in
            self
                .sendSingle(
                    to: tx.data.to,
                    amount: tx.data.value,
                    gasLimit: tx.gasData.gasLimit,
                    gasPrice: .legacy(gasPrice: tx.gasData.gasPrice)
                )
                .subscribe { [weak self] fullTransaction in
                    guard let self = self else { return }
                    let record = self.transactionRecord(fullTransaction: fullTransaction)
                    print("Eth tx sent: \(record.id) ")
                    promise(.success(record))
                } onError: { error in
                    promise(.failure(error))
                }
                .disposed(by: self.disposeBag)
        }
    }
}
