//
//  BitcoinAdapter.swift
//  BDKDemoApp
//
//  Created by farid on 9/19/22.
//

import Foundation
import Combine
import BitcoinDevKit

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
    private let transactionsSubject = CurrentValueSubject<[BitcoinDevKit.Transaction], Never>([])
    
    private let wallet: BitcoinDevKit.Wallet
    private let blockchain: BitcoinDevKit.Blockchain
    private let updateTimer = RepeatingTimer(timeInterval: 10)
    private let progressHandler = ProgressHandler()
    private let networkQueue = DispatchQueue(label: "com.portal.network.layer.queue", qos: .userInitiated)
    
    private var adapterState: AdapterState = .empty
    private var balanceSats: UInt64 = 0
    
    init(wallet: Wallet) throws {
        let account = wallet.account
        let fingerprint = account.extendedKey.fingerprint
        let xprv = account.extendedKey.xprv
                
        let descriptor = "wpkh([\(fingerprint)/84'/0'/0']\(xprv)/*)"
        let changeDescriptor = "wpkh([\(fingerprint)/84'/0'/1']\(xprv)/*)"
        
        if let dbPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last?.absoluteString {
            let sqliteConfig = SqliteDbConfiguration(path: dbPath + "portal.sqlite" + "\(account.id)")
            let dbConfig = DatabaseConfig.sqlite(config: sqliteConfig)
            let electrum = ElectrumConfig(url: "ssl://electrum.blockstream.info:60002", socks5: nil, retry: 5, timeout: nil, stopGap: 10)
            let blockchainConfig = BlockchainConfig.electrum(config: electrum)
            
            do {
                self.blockchain = try Blockchain(config: blockchainConfig)
                self.wallet = try BitcoinDevKit.Wallet(
                    descriptor: descriptor,
                    changeDescriptor: changeDescriptor,
                    network: Network.testnet,
                    databaseConfig: dbConfig
                )
                self.loadCache()
                self.updateTimer.eventHandler = { [weak self] in
                    self?.sync()
                }
            } catch {
                throw error
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
            update(state: .failed(error))
        }
    }
    
    private func sync() {
        guard adapterState != .empty, adapterState != .syncing else { return }
        
        update(state: .syncing)
        
        networkQueue.async {
            do {
                try self.wallet.sync(blockchain: self.blockchain, progress: self.progressHandler)
            } catch {
                DispatchQueue.main.async {
                    self.update(state: .failed(error))
                }
            }
            
            do {
                try self.fetchBalance()
                try self.fetchTransactions()

                DispatchQueue.main.async {
                    self.update(state: .synced)
                }
            } catch {
                DispatchQueue.main.async {
                    self.update(state: .failed(error))
                }
            }
        }
    }
    
    private func fetchBalance() throws {
        balanceSats = try wallet.getBalance()
        balanceUpdatedSubject.send()
    }
    
    private func fetchTransactions() throws {
        update(txs:
            try wallet.getTransactions().sorted(by: {
                switch $0 {
                case .confirmed(_, let confirmation_a):
                    switch $1 {
                    case .confirmed(_, let confirmation_b):
                        return confirmation_a.timestamp > confirmation_b.timestamp
                    default:
                        return false
                    }
                default:
                    switch $1 {
                    case .unconfirmed(_):
                        return true
                    default:
                        return false
                    }
                } })
        )
    }
    
    private func update(state: AdapterState) {
        adapterState = state
        stateUpdatedSubject.send()
    }
    
    private func update(txs: [BitcoinDevKit.Transaction]) {
        transactionsSubject.send(txs)
    }
}

extension BitcoinAdapter {
    func send(to: String, amount: String, completion: @escaping (Error?) -> Void) {
        do {
            let walletBalance = try wallet.getBalance()
            if let amountToSend = UInt64(amount), walletBalance > amountToSend {
                let psbt = try TxBuilder().addRecipient(address: to, amount: amountToSend).enableRbf().finish(wallet: wallet)
                let finalized = try wallet.sign(psbt: psbt)
                if finalized {
                    print("Tx id: \(psbt.txid())")
                    try blockchain.broadcast(psbt: psbt)
                    completion(nil)
                }
            } else {
                completion(SendFlowError.insufficientAmount)
            }
        } catch {
            completion(error)
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
    
    var debugInfo: String {
        "Btc adapter debug"
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
    var transactionRecords: AnyPublisher<[Transaction], Never> {
        transactionsSubject.eraseToAnyPublisher()
    }
}

