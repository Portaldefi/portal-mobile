//
//  WalletViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import Foundation
import BitcoinDevKit

class WalletViewModel: ObservableObject {
    class ProgressHandler: BitcoinDevKit.Progress {
        func update(progress: Float, message: String?) {
            print("progress: \(progress), message: \(message ?? "-")")
        }
    }
    
    enum State {
        case empty
        case loading
        case failed(Error)
        case loaded(Wallet, Blockchain)
    }
    
    enum SyncState {
        case empty
        case syncing
        case synced
        case failed(Error)
    }
    
    private(set) var key = "private_key"
    
    @Published private(set) var state = State.empty
    @Published private(set) var syncState = SyncState.empty
    @Published private(set) var balance: UInt64 = 0
    @Published private(set) var transactions: [BitcoinDevKit.Transaction] = []
    @Published private(set) var items: [WalletItem] = []
    @Published private(set) var syncStatusString = "Not synced"
    @Published private(set) var isSynced: Bool = false
    
    private(set) var progressHandler = ProgressHandler()
    
    
    func load() {
        state = .loading
        let db = DatabaseConfig.memory
        let descriptor = "wpkh(tprv8ZgxMBicQKsPeSitUfdxhsVaf4BXAASVAbHypn2jnPcjmQZvqZYkeqx7EHQTWvdubTSDa5ben7zHC7sUsx4d8tbTvWdUtHzR8uhHg2CW7MT/*)"
        let electrum = ElectrumConfig(url: "ssl://electrum.blockstream.info:60002", socks5: nil, retry: 5, timeout: nil, stopGap: 10)
        let blockchainConfig = BlockchainConfig.electrum(config: electrum)
        do {
            let blockchain = try Blockchain(config: blockchainConfig)
            let wallet = try Wallet(descriptor: descriptor, changeDescriptor: nil, network: Network.testnet, databaseConfig: db)
            state = State.loaded(wallet, blockchain)
        } catch let error {
            state = State.failed(error)
        }
        sync()
    }
    
    func sync() {
        switch self.state {
        case .loaded(let wallet, let blockchain):
            syncStatusString = "Syncing..."
            self.syncState = .syncing
            self.isSynced = false
//            do {
            DispatchQueue.global(qos: .userInitiated).async {
                try! wallet.sync(blockchain: blockchain, progress: self.progressHandler)
                let wallet_transactions = try! wallet.getTransactions()
                DispatchQueue.main.async {
                    self.syncState = .synced
                    self.syncStatusString = "Synced!"
                    self.isSynced = true
                    self.balance = try! wallet.getBalance()
                    self.items = [WalletItem(description: "On-chain", balance: self.balance)]
                    self.transactions = wallet_transactions.sorted(by: {
                    switch $0 {
                    case .confirmed(_, let confirmation_a):
                        switch $1 {
                        case .confirmed(_, let confirmation_b): return confirmation_a.timestamp > confirmation_b.timestamp
                        default: return false
                        }
                    default:
                        switch $1 {
                        case .unconfirmed(_): return true
                        default: return false
                        }
                    } })
                }
            }
//          } catch let error {
//              print(error)
//              self.syncState = .failed(error)
//          }
        default: do { }
            print("default")
        }
    }
}

extension Date {
    func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}

