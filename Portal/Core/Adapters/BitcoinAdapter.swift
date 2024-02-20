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

final class BitcoinAdapter {
    private enum DereviationPathBranch: Int {
        case external = 0, `internal`
    }
    
    private let electrumTestNetURL = "ssl://electrum.blockstream.info:60002"
    private let espolaRegTestURL = "http:/localhost:3002"
    
    private let coinRate: Decimal = pow(10, 8)
    
    private let stateUpdatedSubject = PassthroughSubject<Void, Never>()
    private let balanceUpdatedSubject = PassthroughSubject<Void, Never>()
    private let transactionsSubject = CurrentValueSubject<[TransactionRecord], Never>([])
    
    private let wallet: BitcoinDevKit.Wallet
    private let blockchain: BitcoinDevKit.Blockchain
    private let updateTimer: RepeatingTimer
    private let networkQueue = DispatchQueue(label: "com.portal.network.layer.queue", qos: .userInitiated)
    
    private var adapterState: AdapterState = .synced
    private var _balance = Balance(immature: 0, trustedPending: 0, untrustedPending: 0, confirmed: 0, spendable: 0, total: 0)
    private var _transactions = [TransactionDetails]()
    
    private let notificationService: INotificationService
    private let txDataStorage: ITxUserDataStorage
    
    static private func descriptor(derivedKey: String, network: Network) throws -> Descriptor {
        try Descriptor(descriptor: "wpkh(\(derivedKey))", network: network)
    }
    
    static private func dereviationPath(index: Int, branch: DereviationPathBranch) throws -> DerivationPath {
        try DerivationPath(path: "m/84h/0h/\(index)h/\(branch.rawValue)")
    }
        
    init(wallet: Wallet, txDataStorage: ITxUserDataStorage, notificationService: INotificationService) throws {
        self.txDataStorage = txDataStorage
        self.notificationService = notificationService
        
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
                updateTimer = RepeatingTimer(timeInterval: 30)
            case .regtest:
                let espolaConfig = EsploraConfig(
                    baseUrl: espolaRegTestURL,
                    proxy: nil,
                    concurrency: nil,
                    stopGap: 10,
                    timeout: nil
                )
                blockchainConfig = BlockchainConfig.esplora(config: espolaConfig)
                updateTimer = RepeatingTimer(timeInterval: 5)

                //RPC Config is broken
                
//                let rpcConfig = RpcConfig(
//                    url: "localhost:18443",
//                    auth: .userPass(username: "lnd", password: "lnd"),
//                    network: .regtest,
//                    walletName: wallet.account.id,
//                    syncParams: nil
//                )

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
        } else {
            throw BtcAdapterError.dbNotFound
        }
    }
    
    private func syncData() {
        if case .syncing = adapterState { return }
        
        update(state: .syncing(progress: 0, lastBlockDate: nil))
        
        networkQueue.async {
            do {
//                print("SYNCING WITH BITCOIN NETWORK...")
//                let start = DispatchTime.now()
                try self.wallet.sync(blockchain: self.blockchain, progress: nil)
//                let end = DispatchTime.now()
//                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
//                let timeInterval = Double(nanoTime)/1_000_000_000
//                print("SYNCED in \(timeInterval) seconds")
                try self.update()
                self.update(state: .synced)
            } catch {
                print("BITCOIN NETWORK SYNC ERROR: \(error)")
                self.update(state: .notSynced(error: error))
                print("Recyncing...")
                self.syncData()
            }
        }
    }
    
    private func update() throws {
        try updateBalance()
        try updateTransactions()
    }
    
    private func update(state: AdapterState) {
        adapterState = state
        stateUpdatedSubject.send()
    }
    
    private func updateBalance() throws {
        let oldValue = _balance
        _balance = try wallet.getBalance()
        
        if _balance.spendable != oldValue.spendable {
            balanceUpdatedSubject.send()
        }
    }
    
    private func updateTransactions() throws {
        let transactions = try wallet.listTransactions(includeRaw: true)
        
        guard !transactions.isEmpty else { return }
        
        var shouldUpdate = transactions.count != _transactions.count
        
        if !shouldUpdate, transactions.count == _transactions.count {
            for i in 0...transactions.count - 1 {
                if transactions[i].confirmationTime != _transactions[i].confirmationTime {
                    shouldUpdate = true
                    break
                }
            }
        }
        
        guard shouldUpdate else { return }
        
        _transactions = transactions
        
        var txRecords = [TransactionRecord]()
                
        for txRecord in transactions {
            let data = txDataStorage.fetch(source: .bitcoin, id: txRecord.txid)
            let userData = TxUserData(data: data)
            let record = BTCTransactionRecord(transaction: txRecord, userData: userData)
            
            txRecords.append(record)
                        
            guard
                lastKnownTxTimestamp > 0,
                let timestamp = record.timestamp,
                case .received(let coin) = record.type,
                timestamp > lastKnownTxTimestamp
            else { continue }
                                            
            let satAmount = record.amount ?? 0
            let btcAmount = satAmount / 100_000_000
            let message = "You've received \(btcAmount) \(coin.code.uppercased())"
            
            notificationService.sendLocalNotification(
                title: "Received \(coin.code.uppercased())",
                body: message
            )
        }
        
        if
            let mostRecentTxTimestamp = txRecords.compactMap({ $0.timestamp }).max(),
            mostRecentTxTimestamp > lastKnownTxTimestamp
        {
            UserDefaults.standard.setValue(mostRecentTxTimestamp, forKey: "knownTxTimestamp.btc")
        }
        
        transactionsSubject.send(txRecords)
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
        syncData()
    }
    
    var blockchainHeight: Int32 {
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
        (try? wallet.getAddress(addressIndex: AddressIndex.lastUnused).address.asString()) ?? String()
    }
}

extension BitcoinAdapter: ITransactionsAdapter {
    var lastKnownTxTimestamp: Int {
        UserDefaults.standard.integer(forKey: "knownTxTimestamp.btc")
    }
    
    var onTxsUpdate: AnyPublisher<Void, Never> {
        balanceUpdated
    }
    
    var transactionRecords: [TransactionRecord] {
        var txRecords = [TransactionRecord]()
        
        for txRecord in _transactions {
            let data = txDataStorage.fetch(source: .bitcoin, id: txRecord.txid)
            let userData = TxUserData(data: data)
            let record = BTCTransactionRecord(transaction: txRecord, userData: userData)
            
            txRecords.append(record)
        }
        
        return (txRecords).sorted(by: { $0.timestamp ?? 1 > $1.timestamp ?? 0 })
    }
}

extension BitcoinAdapter: ISendBitcoinAdapter {
    func rawTransaction(amount: UInt64, address: String) throws -> Transaction {
        let receiverAddress = try Address(address: address)
        let receiverAddressScript = receiverAddress.scriptPubkey()
        let txBuilderResult: TxBuilderResult
//        let utxos = try? wallet.listUnspent()
//        let outpoints = utxos?.filter{ !$0.isSpent && $0.keychain == .external }.map { $0.outpoint } ?? []
        
        txBuilderResult = try TxBuilder()
//            .addUtxos(outpoints: outpoints)
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
    
    func send(amount: Decimal, address: String, fee: Int?) throws -> TransactionRecord {
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
            let data = txDataStorage.fetch(source: .bitcoin, id: txDetails.txid)
            let userData = TxUserData(data: data)
            return BTCTransactionRecord(transaction: txDetails, userData: userData)
        } else {
            throw SendFlowError.error("Tx not finalized")
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
            let data = txDataStorage.fetch(source: .bitcoin, id: txDetails.txid)
            let userData = TxUserData(data: data)
            let record = BTCTransactionRecord(transaction: txDetails, userData: userData)
            return(record)
        } else {
            throw SendFlowError.error("Tx not finalized")
        }
    }
    
    func sendMax(address: String, fee: Int?) throws -> TransactionRecord {
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
            let data = txDataStorage.fetch(source: .bitcoin, id: txDetails.txid)
            let userData = TxUserData(data: data)
            return BTCTransactionRecord(transaction: txDetails, userData: userData)
        } else {
            throw SendFlowError.error("Tx not finalized")
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
