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
    private enum DereviationPathBranch: Int {
        case external = 0, `internal`
    }
    
    private let electrumURL = "ssl://electrum.blockstream.info:60002"
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
    
    static private func descriptor(derivedKey: String, network: Network) throws -> Descriptor {
        try Descriptor(descriptor: "wpkh(\(derivedKey))", network: network)
    }
    
    static private func dereviationPath(index: Int, branch: DereviationPathBranch) throws -> DerivationPath {
        try DerivationPath(path: "m/84h/0h/\(index)h/\(branch.rawValue)")
    }
        
    init(wallet: Wallet) throws {
        let network: Network = .testnet
        
        let account = wallet.account
        let accountIndex = account.index
        
        let bip32RootKey = wallet.account.rootKey
        
        let deriviationPath = try Self.dereviationPath(index: accountIndex, branch: .external)
        let derivedKey = try bip32RootKey.derive(path: deriviationPath)
        let descriptor = try Self.descriptor(derivedKey: derivedKey.asString(), network: network)
        
        let changeDerivationPath = try Self.dereviationPath(index: accountIndex, branch: .internal)
        let changeDerivedKey = try bip32RootKey.derive(path: changeDerivationPath)
        let changeDescriptor = try Self.descriptor(derivedKey: changeDerivedKey.asString(), network: network)
        
        if let dbPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last?.absoluteString {
            let sqliteConfig = SqliteDbConfiguration(path: dbPath + "portal.sqlite" + "\(account.id)")
            let dbConfig = DatabaseConfig.sqlite(config: sqliteConfig)
            
            let electrum = ElectrumConfig(
                url: electrumURL,
                socks5: nil,
                retry: 5,
                timeout: nil,
                stopGap: 10,
                validateDomain: false
            )
            
            let blockchainConfig = BlockchainConfig.electrum(config: electrum)
            blockchain = try Blockchain(config: blockchainConfig)
            
            self.wallet = try BitcoinDevKit.Wallet(
                descriptor: descriptor,
                changeDescriptor: changeDescriptor,
                network: network,
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
        Decimal(_balance.spendable + _balance.untrustedPending)/coinRate
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
    func rawTransaction(amount: UInt64, address: String) throws -> [UInt8] {
        let receiverAddress = try Address(address: address)
        let receiverAddressScript = receiverAddress.scriptPubkey()
        let txBuilderResult: TxBuilderResult
        let utxos = try? wallet.listUnspent()
        let outpoints = utxos?.filter{ !$0.isSpent && $0.keychain == .external }.map { $0.outpoint } ?? []
        
        txBuilderResult = try TxBuilder()
            .addUtxos(outpoints: outpoints)
            .addRecipient(script: receiverAddressScript, amount: amount)
            .enableRbf()
            .finish(wallet: wallet)
        
        let psbt = txBuilderResult.psbt
        let txDetails = txBuilderResult.transactionDetails
        print("txDetails: \(txDetails)")
        
        let signed = try wallet.sign(psbt: psbt)
        print("Tx id: \(psbt.txid())")
        print("funding tx serialized: \(psbt.serialize())")
        
        if signed {
            return psbt.extractTx()
        } else {
            throw SendFlowError.error("Tx not finalized")
        }
    }
    
    func send(amount: Decimal, address: String, fee: Int?) -> Combine.Future<TransactionRecord, Error> {
        Future { [unowned self] promise in
            do {
                let satsAmount = UInt64((amount * 100_000_000).double)
                let receiverAddress = try Address(address: address)
                let receiverAddressScript = receiverAddress.scriptPubkey()
                let txBuilderResult: TxBuilderResult
                let utxos = try? wallet.listUnspent()
                let outpoints = utxos?.filter{ !$0.isSpent && $0.keychain == .external }.map { $0.outpoint } ?? []

                if let fee = fee {
                    txBuilderResult = try TxBuilder()
                        .addUtxos(outpoints: outpoints)
                        .addRecipient(script: receiverAddressScript, amount: satsAmount)
                        .feeRate(satPerVbyte: Float(fee))
                        .enableRbf()
                        .finish(wallet: wallet)
                } else {
                    txBuilderResult = try TxBuilder()
                        .addUtxos(outpoints: outpoints)
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
                let utxos = try? wallet.listUnspent()
                let outpoints = utxos?.filter{ !$0.isSpent && $0.keychain == .external }.map { $0.outpoint } ?? []

                if let fee = fee {
                    txBuilderResult = try TxBuilder()
                        .addUtxos(outpoints: outpoints)
                        .drainWallet()
                        .drainTo(script: receiverAddress.scriptPubkey())
                        .feeRate(satPerVbyte: Float(fee))
                        .enableRbf()
                        .finish(wallet: wallet)
                } else {
                    txBuilderResult = try TxBuilder()
                        .addUtxos(outpoints: outpoints)
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
            print(balance)
//            print(try! wallet.listUnspent())
            print(try! wallet.getBalance())
//            print(try! wallet.listTransactions())
            let utxos = try? wallet.listUnspent()
            print(utxos)
            let outpoints = utxos?.filter{ !$0.isSpent && $0.keychain == .external }.map { $0.outpoint } ?? []

            if max {
                if let fee = fee {
                    txBuilderResult = try TxBuilder()
                        .addUtxos(outpoints: outpoints)
                        .drainWallet()
                        .drainTo(script: receiverAddress.scriptPubkey())
                        .feeRate(satPerVbyte: Float(fee))
                        .enableRbf()
                        .finish(wallet: wallet)
                } else {
                    txBuilderResult = try TxBuilder()
                        .addUtxos(outpoints: outpoints)
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
                        .addUtxos(outpoints: outpoints)
                        .addRecipient(script: recieverAddressScript, amount: satsAmount)
                        .feeRate(satPerVbyte: Float(fee))
                        .enableRbf()
                        .finish(wallet: wallet)
                } else {
                    txBuilderResult = try TxBuilder()
                        .addUtxos(outpoints: outpoints)
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
