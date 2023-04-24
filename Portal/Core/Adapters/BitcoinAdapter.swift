//
//  BitcoinAdapter.swift
//  Portal
//
//  Created by farid on 9/19/22.
//

import Foundation
import Combine
import BitcoinDevKit
import HsCryptoKit

final class BitcoinAdapter: IBitcoinKitManager {
    let pubKey: String
    private let ldkManager = Container.lightningKitManager()
    
    private enum DereviationPathBranch: Int {
        case external = 0, `internal`
    }
    
    private let electrumTestNetURL = "ssl://electrum.blockstream.info:60002"
    private let espolaRegTestURL = "http://192.168.1.8:3002"
    var blockChainHeight: Int32 = 0
    
    private let coinRate: Decimal = pow(10, 8)
    
    private let stateUpdatedSubject = PassthroughSubject<Void, Never>()
    private let balanceUpdatedSubject = PassthroughSubject<Void, Never>()
    private let transactionsSubject = CurrentValueSubject<[TransactionRecord], Never>([])
    
    private let wallet: BitcoinDevKit.Wallet
    private let blockchain: BitcoinDevKit.Blockchain
    private let updateTimer = RepeatingTimer(timeInterval: 10)
    private let networkQueue = DispatchQueue(label: "com.portal.network.layer.queue", qos: .userInitiated)
    
    private var adapterState: AdapterState = .synced
    private var _balance = Balance(immature: 0, trustedPending: 0, untrustedPending: 0, confirmed: 0, spendable: 0, total: 0)
    private var _receiveAddress = AddressInfo(index: 0, address: String())
    private var _transactions = [TransactionDetails]()
    
    static private func descriptor(derivedKey: String, network: Network) throws -> Descriptor {
        try Descriptor(descriptor: "wpkh(\(derivedKey))", network: network)
    }
    
    static private func dereviationPath(index: Int, branch: DereviationPathBranch) throws -> DerivationPath {
        try DerivationPath(path: "m/84h/0h/\(index)h/\(branch.rawValue)")
    }
        
    init(wallet: Wallet) throws {
        let network = wallet.account.btcNetwork
        
        let account = wallet.account
        let accountIndex = account.index
        
        let bip32RootKey = try DescriptorSecretKey.fromString(secretKey: wallet.account.rootKey)
        
        let deriviationPath = try Self.dereviationPath(index: accountIndex, branch: .external)
        let derivedKey = try bip32RootKey.derive(path: deriviationPath)
        
        let descriptor = try Self.descriptor(derivedKey: derivedKey.asString(), network: network)
        
        let changeDerivationPath = try Self.dereviationPath(index: accountIndex, branch: .internal)
        let changeDerivedKey = try bip32RootKey.derive(path: changeDerivationPath)
        let changeDescriptor = try Self.descriptor(derivedKey: changeDerivedKey.asString(), network: network)
        
        let keyBytes = derivedKey.asString().bytes
        let keyData = Data(keyBytes)
        
        let compressedKey = Crypto.publicKey(privateKey: keyData, compressed: true)
        self.pubKey = compressedKey.toHexString()

        
        if let dbPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last?.absoluteString {
            let sqliteConfig = SqliteDbConfiguration(path: dbPath + "portal.sqlite" + "\(account.id)")
            let dbConfig = DatabaseConfig.sqlite(config: sqliteConfig)
            let blockchainConfig: BlockchainConfig
            
            switch network {
            case .bitcoin, .signet:
                fatalError("not implemented")
            case .testnet:
                let electrumConfig = ElectrumConfig(
                    url: electrumTestNetURL,
                    socks5: nil,
                    retry: 5,
                    timeout: nil,
                    stopGap: 10,
                    validateDomain: false
                )
                blockchainConfig = BlockchainConfig.electrum(config: electrumConfig)
            case .regtest:
                let espolaConfig = EsploraConfig(
                    baseUrl: espolaRegTestURL,
                    proxy: nil,
                    concurrency: nil,
                    stopGap: 10,
                    timeout: nil
                )
                blockchainConfig = BlockchainConfig.esplora(config: espolaConfig)
                
//                let rpcConfig = RpcConfig(
//                    url: "localhost:18454",
//                    auth: .userPass(username: "polaruser", password: "polarpass"),
//                    network: .regtest,
//                    walletName: "portal.regtest",
//                    syncParams: nil
//                )
//
//                blockchainConfig = BlockchainConfig.rpc(config: rpcConfig)
            }
                        
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
            
            Task {
                try await ldkManager.start()
            }
        } else {
            throw BtcAdapterError.dbNotFound
        }
    }
    
    private func syncData() {
        if case .syncing = adapterState { return }
        
        update(state: .syncing(progress: 0, lastBlockDate: nil))
        
        networkQueue.async {
            do {
                print("SYNCING WITH BITCOIN NETWORK...")
                let start = DispatchTime.now()
                try self.wallet.sync(blockchain: self.blockchain, progress: nil)
                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                let timeInterval = Double(nanoTime)/1_000_000_000
                print("SYNCED in \(timeInterval) seconds")
                try self.update()
                self.update(state: .synced)
            } catch {
                print("BITCOIN NETWORK SYNC ERROR: \(error)")
                self.update(state: .notSynced(error: error))
            }
        }
    }
    
    private func update() throws {
        try updateAddress()
        try updateBalance()
        try updateTransactions()
        try updateBlockHeight()
    }
    
    private func update(state: AdapterState) {
        adapterState = state
        stateUpdatedSubject.send()
    }
    
    private func updateBalance() throws {
        let oldValue = _balance
        _balance = try wallet.getBalance()
        if _balance != oldValue {
            balanceUpdatedSubject.send()
        }
    }
    
    private func updateAddress() throws {
        _receiveAddress = try wallet.getAddress(addressIndex: AddressIndex.lastUnused)
    }
    
    private func updateTransactions() throws {
        let transactions = try wallet.listTransactions(includeRaw: true)
        guard transactions != _transactions else { return }
        _transactions = transactions
        let txRecords = transactions.map{ TransactionRecord(transaction: $0) }
        transactionsSubject.send(txRecords)
    }
    
    private func updateBlockHeight() throws {
        blockChainHeight = Int32(try blockchain.getHeight())
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
        blockChainHeight
    }
}

import Factory

extension BitcoinAdapter: IBalanceAdapter {
    var state: AdapterState {
        adapterState
    }
    
    var L1Balance: Decimal {
        Decimal(_balance.spendable + _balance.untrustedPending)/coinRate
    }
    
    var balance: Decimal {
        ldkManager.channelBalance/1000/coinRate
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
        transactionsSubject
            .combineLatest(ldkManager.transactionsPublisher) { btcTxs, lightningTxs in
                (btcTxs + lightningTxs).sorted(by: { $0.timestamp ?? 1 > $1.timestamp ?? 0 })
            }
            .eraseToAnyPublisher()
    }
}

extension BitcoinAdapter: ISendBitcoinAdapter {
    func rawTransaction(amount: UInt64, address: String) throws -> Transaction {
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
        
        let signed = try wallet.sign(psbt: psbt, signOptions: .none)
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
                
                let finalized = try wallet.sign(psbt: psbt, signOptions: .none)
                print("Tx id: \(psbt.txid())")
                
                if finalized {
                    try blockchain.broadcast(transaction: psbt.extractTx())
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
    
    func send(amount: Decimal, address: String) throws -> TransactionRecord {
        let satsAmount = UInt64((amount * 100_000_000).double)
        let receiverAddress = try Address(address: address)
        let receiverAddressScript = receiverAddress.scriptPubkey()
        let txBuilderResult: TxBuilderResult
        let utxos = try? wallet.listUnspent()
        let outpoints = utxos?.filter{ !$0.isSpent && $0.keychain == .external }.map { $0.outpoint } ?? []

        txBuilderResult = try TxBuilder()
            .addUtxos(outpoints: outpoints)
            .addRecipient(script: receiverAddressScript, amount: satsAmount)
            .enableRbf()
            .finish(wallet: wallet)
        
        let psbt = txBuilderResult.psbt
        let txDetails = txBuilderResult.transactionDetails
        print("txDetails: \(txDetails)")
        
        let finalized = try wallet.sign(psbt: psbt, signOptions: .none)
        print("Tx id: \(psbt.txid())")
        
        if finalized {
            try blockchain.broadcast(transaction: psbt.extractTx())
            let record = TransactionRecord(transaction: txDetails)
            return(record)
        } else {
            throw SendFlowError.error("Tx not finalized")
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

                let finalized = try wallet.sign(psbt: psbt, signOptions: .none)
                print("Tx id: \(psbt.txid())")

                if finalized {
                    try blockchain.broadcast(transaction: psbt.extractTx())
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
            let utxos = try? wallet.listUnspent()
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
        _ = try Address(address: address)
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
