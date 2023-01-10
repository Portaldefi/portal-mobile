//
//  BitcoinAdapter.swift
//  Portal
//
//  Created by farid on 9/19/22.
//

import Foundation
import Combine
import BitcoinDevKit
import BitcoinAddressValidator

class ProgressHandler: BitcoinDevKit.Progress {
    func update(progress: Float, message: String?) {
        print("progress: \(progress), message: \(message ?? "-")")
    }
}

final class BitcoinAdapter {
    enum BtcAdapterError: Error {
        case dbNotFound
        
        var descriptioin: String {
            switch self {
            case .dbNotFound:
                return "DB not found"
            }
        }
    }
        
    private let stateUpdatedSubject = PassthroughSubject<Void, Never>()
    private let balanceUpdatedSubject = PassthroughSubject<Void, Never>()
    private let transactionsSubject = CurrentValueSubject<[TransactionRecord], Never>([])
    
    private let wallet: BitcoinDevKit.Wallet
    private let blockchain: BitcoinDevKit.Blockchain
    private let updateTimer = RepeatingTimer(timeInterval: 60)
    private let progressHandler = ProgressHandler()
    private let networkQueue = DispatchQueue(label: "com.portal.network.layer.queue", qos: .userInitiated)
    
    private var adapterState: AdapterState = .synced
    private var balanceSats: UInt64 = 0
    
    init(wallet: Wallet) throws {
        let account = wallet.account
        let bip32RootKey = wallet.account.rootKey
        let deriviationPath = try DerivationPath(path: "m/84h/0h/\(account.index)h/0")
        let derivedKey = try bip32RootKey.derive(path: deriviationPath)
        let descriptor = "wpkh(\(derivedKey.asString()))"
        
        if let dbPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last?.absoluteString {
            let sqliteConfig = SqliteDbConfiguration(path: dbPath + "portal.sqlite" + "\(account.id)")
            let dbConfig = DatabaseConfig.sqlite(config: sqliteConfig)
            let electrum = ElectrumConfig(url: "ssl://electrum.blockstream.info:60002", socks5: nil, retry: 5, timeout: nil, stopGap: 10)
            let blockchainConfig = BlockchainConfig.electrum(config: electrum)
            
            self.blockchain = try Blockchain(config: blockchainConfig)
            
            self.wallet = try BitcoinDevKit.Wallet(
                descriptor: descriptor,
                changeDescriptor: nil,
                network: Network.testnet,
                databaseConfig: dbConfig
            )
                        
            self.loadCache()
            
            self.updateTimer.eventHandler = { [weak self] in
                self?.sync()
            }
        } else {
            throw BtcAdapterError.dbNotFound
        }
    }
    
    private func loadCache() {
        do {
            try fetchBalance()
            try fetchTransactions()
        } catch {
            update(state: .notSynced(error: error))
        }
    }
    
    private func sync() {        
        print("Syncing btc network...")
        
        update(state: .syncing(progress: 0, lastBlockDate: nil))
        
        networkQueue.async {
            do {
                try self.wallet.sync(blockchain: self.blockchain, progress: self.progressHandler)
            } catch {
                DispatchQueue.main.async {
                    print("Btc network synced error: \(error)")
                    self.update(state: .notSynced(error: error))
                }
            }
            
            do {
                try self.fetchBalance()
                try self.fetchTransactions()

                DispatchQueue.main.async {
                    print("Btc network synced...")
                    self.update(state: .synced)
                }
            } catch {
                DispatchQueue.main.async {
                    print("Btc network synced error: \(error)")
                    self.update(state: .notSynced(error: error))
                }
            }
        }
    }
    
    private func fetchBalance() throws {
        balanceSats = try wallet.getBalance().total
        balanceUpdatedSubject.send()
    }
    
    private func fetchTransactions() throws {
        let txs = try wallet.listTransactions()
        let convertedTxs = txs.map{ TransactionRecord(transaction: $0) }
        update(txs: convertedTxs)
    }
    
    private func update(state: AdapterState) {
        adapterState = state
        stateUpdatedSubject.send()
    }
    
    private func update(txs: [TransactionRecord]) {
        DispatchQueue.main.async {
            self.transactionsSubject.send(txs)
        }
    }
}

extension BitcoinAdapter: IAdapter {
    func start() {
        updateTimer.resume()
    }
    
    func stop() {
        updateTimer.suspend()
    }
    
    func refresh() {
        sync()
    }
    
    var blockchainHeight: Int32 {
        if let height = try? blockchain.getHeight() {
            return Int32(height)
        }
        return 0
    }
}

extension BitcoinAdapter: IBalanceAdapter {
    var state: AdapterState {
        adapterState
    }
    
    var balance: Decimal {
        Decimal(balanceSats)/100_000_000
    }
    
    var balanceStateUpdated: AnyPublisher<Void, Never> {
        stateUpdatedSubject.eraseToAnyPublisher()
    }
    
    var balanceUpdated: AnyPublisher<Void, Never> {
        balanceUpdatedSubject.eraseToAnyPublisher()
    }
}

extension BitcoinAdapter: IDepositAdapter {
    var receiveAddress: String {
        do {
            let addressInfo = try wallet.getAddress(addressIndex: AddressIndex.lastUnused)
            print("======================================================")
            print("btc receive address: \(addressInfo.address)")
            print("======================================================")
            return addressInfo.address
        } catch {
            return "ERROR"
        }
    }
}

extension BitcoinAdapter: ITransactionsAdapter {
    var transactionRecords: AnyPublisher<[TransactionRecord], Never> {
        transactionsSubject.eraseToAnyPublisher()
    }
}

extension BitcoinAdapter: ISendBitcoinAdapter {
    func send(amount: Decimal, address: String, fee: Int?) -> Future<String, Error> {
        Future { [unowned self] promise in
            do {
                let walletBalance = try wallet.getBalance().total
                let satAmountDouble = amount.double * 100_000_000
                let satAmountInt = UInt64(satAmountDouble)
                let recieverAddress = try Address(address: address)
                let recieverAddressScript = recieverAddress.scriptPubkey()
                let txBuilderResult: TxBuilderResult
                
                if walletBalance >= satAmountInt {
                    if let fee = fee {
                        txBuilderResult = try TxBuilder()
                            .addRecipient(script: recieverAddressScript, amount: satAmountInt)
                            .feeRate(satPerVbyte: Float(fee))
                            .enableRbf()
                            .finish(wallet: wallet)
                    } else {
                        txBuilderResult = try TxBuilder()
                            .addRecipient(script: recieverAddressScript, amount: satAmountInt)
                            .enableRbf()
                            .finish(wallet: wallet)
                    }
                    
                    let psbt = txBuilderResult.psbt
                    let txDetails = txBuilderResult.transactionDetails
                    print("txDetails: \(txDetails)")
                    
                    let finalized = try wallet.sign(psbt: psbt)
                    print("Tx id: \(psbt.txid())")
                    
                    if finalized {
                        try blockchain.broadcast(psbt: psbt)
                        sync()
                        promise(.success(psbt.txid()))
                    } else {
                        promise(.failure(SendFlowError.error("Tx not finalized")))
                    }
                } else {
                    promise(.failure(SendFlowError.insufficientAmount))
                }
            } catch {
                promise(.failure(error))
            }
        }
    }
    
    func sendMax(address: String, fee: Int?) -> Future<String, Error> {
        Future { [unowned self] promise in
            do {
                let txBuilderResult: TxBuilderResult

                if let fee = fee {
                    txBuilderResult = try TxBuilder()
                        .drainWallet()
                        .drainTo(address: address)
                        .feeRate(satPerVbyte: Float(fee))
                        .enableRbf()
                        .finish(wallet: wallet)
                } else {
                    txBuilderResult = try TxBuilder()
                        .drainWallet()
                        .drainTo(address: address)
                        .enableRbf()
                        .finish(wallet: wallet)
                }
                
                let psbt = txBuilderResult.psbt
                let txDetails = txBuilderResult.transactionDetails
                print("txDetails: \(txDetails)")

                let finalized = try wallet.sign(psbt: psbt)
                print("Tx id: \(psbt.txid())")

                if finalized {
                    try blockchain.broadcast(psbt: psbt)
                    sync()
                    promise(.success(psbt.txid()))
                } else {
                    promise(.failure(SendFlowError.error("Tx not finalized")))
                }
            } catch {
                promise(.failure(error))
            }
        }
    }
    
    func fee(max: Bool, address: String, amount: Decimal, fee: Int?) throws -> UInt64? {
        do {
            let txBuilderResult: TxBuilderResult
            
            if max {
                if let fee = fee {
                    txBuilderResult = try TxBuilder()
                        .drainWallet()
                        .drainTo(address: address)
                        .feeRate(satPerVbyte: Float(fee))
                        .enableRbf()
                        .finish(wallet: wallet)
                } else {
                    txBuilderResult = try TxBuilder()
                        .drainWallet()
                        .drainTo(address: address)
                        .enableRbf()
                        .finish(wallet: wallet)
                }
                
                return txBuilderResult.transactionDetails.fee
            } else {
                let walletBalance = try wallet.getBalance().total
                let satAmountDouble = amount.double * 100_000_000
                let satAmountInt = UInt64(satAmountDouble)
                let recieverAddress = try Address(address: address)
                let recieverAddressScript = recieverAddress.scriptPubkey()
                
                if walletBalance >= satAmountInt {
                    if let fee = fee {
                        txBuilderResult = try TxBuilder()
                            .addRecipient(script: recieverAddressScript, amount: satAmountInt)
                            .feeRate(satPerVbyte: Float(fee))
                            .enableRbf()
                            .finish(wallet: wallet)
                    } else {
                        txBuilderResult = try TxBuilder()
                            .addRecipient(script: recieverAddressScript, amount: satAmountInt)
                            .enableRbf()
                            .finish(wallet: wallet)
                    }
                    
                    return txBuilderResult.transactionDetails.fee
                } else {
                    throw SendFlowError.insufficientAmount
                }
            }
        } catch {
            throw error
        }
    }
    
    func validate(address: String) throws {
        if !BitcoinAddressValidator.isValid(address: address) {
            throw SendFlowError.addressIsntValid
        }
    }
}

