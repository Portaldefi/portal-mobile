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

final class BitcoinAdapter {
    private let coinRate: Decimal = pow(10, 8)
    
    private let stateUpdatedSubject = PassthroughSubject<Void, Never>()
    private let balanceUpdatedSubject = PassthroughSubject<Void, Never>()
    private let transactionsSubject = CurrentValueSubject<[TransactionRecord], Never>([])
    
    private let wallet: BitcoinDevKit.Wallet
    private let blockchain: BitcoinDevKit.Blockchain
    private let updateTimer = RepeatingTimer(timeInterval: 180)
    private let networkQueue = DispatchQueue(label: "com.portal.network.layer.queue", qos: .userInitiated)
    
    private var adapterState: AdapterState = .syncing(progress: 0, lastBlockDate: nil)
    private var _balance = Balance(immature: 0, trustedPending: 0, untrustedPending: 0, confirmed: 0, spendable: 0, total: 0)
    private var _receiveAddress = AddressInfo(index: 0, address: String())
        
    init(wallet: Wallet) throws {
        let account = wallet.account
        let bip32RootKey = wallet.account.rootKey
        let deriviationPath = try DerivationPath(path: "m/84h/0h/\(account.index)h/0")
        let derivedKey = try bip32RootKey.derive(path: deriviationPath)
        let descriptor = try Descriptor(descriptor: "wpkh(\(derivedKey.asString()))", network: .testnet)
        
        if let dbPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last?.absoluteString {
            let sqliteConfig = SqliteDbConfiguration(path: dbPath + "portal.sqlite" + "\(account.id)")
            let dbConfig = DatabaseConfig.sqlite(config: sqliteConfig)
            let electrum = ElectrumConfig(url: "ssl://electrum.blockstream.info:60002", socks5: nil, retry: 5, timeout: nil, stopGap: 10, validateDomain: false)
            let blockchainConfig = BlockchainConfig.electrum(config: electrum)
            
            blockchain = try Blockchain(config: blockchainConfig)
            
            self.wallet = try BitcoinDevKit.Wallet(
                descriptor: descriptor,
                changeDescriptor: nil,
                network: Network.testnet,
                databaseConfig: dbConfig
            )
            
            try update()
            
            updateTimer.eventHandler = { [unowned self] in
                self.syncData()
            }
        } else {
            throw BtcAdapterError.dbNotFound
        }
    }
    
    private func syncData() {
        update(state: .syncing(progress: 0, lastBlockDate: nil))
        
        do {
            print("SYNCING WITH BITCOIN NETWORK...")
            try wallet.sync(blockchain: blockchain, progress: nil)
            print("BITCOIN NETWORK SYNCED")
            try update()
            print("BITCOIN DATA UPDATED")
            update(state: .synced)
        } catch {
            print("BITCOIN NETWORK SYNC ERROR: \(error)")
            update(state: .notSynced(error: error))
        }
    }
    
    private func update() throws {
        try updateAddress()
        try updateBalance()
        print("BITCOIN BALANCE UPDATED")
        try updateTransactions()
        print("BITCOIN TRANSACTIONS UPDATED")
    }
    
    private func update(state: AdapterState) {
        adapterState = state
        stateUpdatedSubject.send()
    }
    
    private func updateBalance() throws {
        _balance = try wallet.getBalance()
        balanceUpdatedSubject.send()
    }
    
    private func updateAddress() throws {
        let addressInfo = try wallet.getAddress(addressIndex: AddressIndex.lastUnused)
        _receiveAddress = addressInfo
    }
    
    private func updateTransactions() throws {
        let transactions = try wallet.listTransactions().map{ TransactionRecord(transaction: $0) }
        transactionsSubject.send(transactions)
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
        Decimal(_balance.spendable)/coinRate
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
        _receiveAddress.address
    }
}

extension BitcoinAdapter: ITransactionsAdapter {
    var transactionRecords: AnyPublisher<[TransactionRecord], Never> {
        transactionsSubject.eraseToAnyPublisher()
    }
}

extension BitcoinAdapter: ISendBitcoinAdapter {
    func send(amount: Decimal, address: String, fee: Int?) -> Combine.Future<TransactionRecord, Error> {
        Future { [unowned self] promise in
            do {
                let satsAmount = UInt64((amount * 100_000_000).double)
                let receiverAddress = try Address(address: address)
                let receiverAddressScript = receiverAddress.scriptPubkey()
                let txBuilderResult: TxBuilderResult
                
                if let fee = fee {
                    txBuilderResult = try TxBuilder()
                        .addRecipient(script: receiverAddressScript, amount: satsAmount)
                        .feeRate(satPerVbyte: Float(fee))
                        .enableRbf()
                        .finish(wallet: wallet)
                } else {
                    txBuilderResult = try TxBuilder()
                        .addRecipient(script: receiverAddressScript, amount: satsAmount)
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
                    let record = TransactionRecord(transaction: txDetails)
                    promise(.success(record))
                } else {
                    promise(.failure(SendFlowError.error("Tx not finalized")))
                }
            } catch {
                promise(.failure(error))
            }
        }
    }
    
    func sendMax(address: String, fee: Int?) -> Combine.Future<TransactionRecord, Error> {
        Future { [unowned self] promise in
            do {
                let txBuilderResult: TxBuilderResult
                let receiverAddress = try Address(address: address)

                if let fee = fee {
                    txBuilderResult = try TxBuilder()
                        .drainWallet()
                        .drainTo(script: receiverAddress.scriptPubkey())
                        .feeRate(satPerVbyte: Float(fee))
                        .enableRbf()
                        .finish(wallet: wallet)
                } else {
                    txBuilderResult = try TxBuilder()
                        .drainWallet()
                        .drainTo(script: receiverAddress.scriptPubkey())
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
                    let record = TransactionRecord(transaction: txDetails)
                    promise(.success(record))
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
            let receiverAddress = try Address(address: address)
            
            if max {
                if let fee = fee {
                    txBuilderResult = try TxBuilder()
                        .drainWallet()
                        .drainTo(script: receiverAddress.scriptPubkey())
                        .feeRate(satPerVbyte: Float(fee))
                        .enableRbf()
                        .finish(wallet: wallet)
                } else {
                    txBuilderResult = try TxBuilder()
                        .drainWallet()
                        .drainTo(script: receiverAddress.scriptPubkey())
                        .enableRbf()
                        .finish(wallet: wallet)
                }
                
                return txBuilderResult.transactionDetails.fee
            } else {
                let satsAmount = UInt64((amount * 100_000_000).double)
                let recieverAddress = try Address(address: address)
                let recieverAddressScript = recieverAddress.scriptPubkey()
                
                if let fee = fee {
                    txBuilderResult = try TxBuilder()
                        .addRecipient(script: recieverAddressScript, amount: satsAmount)
                        .feeRate(satPerVbyte: Float(fee))
                        .enableRbf()
                        .finish(wallet: wallet)
                } else {
                    txBuilderResult = try TxBuilder()
                        .addRecipient(script: recieverAddressScript, amount: satsAmount)
                        .enableRbf()
                        .finish(wallet: wallet)
                }
                
                return txBuilderResult.transactionDetails.fee
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

extension BitcoinAdapter {
    enum BtcAdapterError: Error {
        case dbNotFound
        
        var descriptioin: String {
            switch self {
            case .dbNotFound:
                return "DB not found"
            }
        }
    }
}
