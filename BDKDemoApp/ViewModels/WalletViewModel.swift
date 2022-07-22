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
        
        let stringsArray = ["fiscal", "ribbon", "chief", "chest", "truly", "rough", "woman", "ugly", "opera", "language", "raccoon", "victory", "expose", "elder", "asthma", "curious", "special", "cactus", "train", "equip", "exchange", "artist", "journey", "dish"]
        let mnemonic = String(stringsArray.reduce(String(), { $0 + " " + $1}).dropFirst())
        let restoredExtendedKey = try! restoreExtendedKey(network: Network.testnet, mnemonic: mnemonic, password: "salty_password")
        let descriptor = "wpkh([\(restoredExtendedKey.fingerprint)/44'/0'/0']\(restoredExtendedKey.xprv)/*)"
        let changeDescriptor = "wpkh([\(restoredExtendedKey.fingerprint)/44'/0'/1']\(restoredExtendedKey.xprv)/*)"
        
        print(restoredExtendedKey.mnemonic)
        print(restoredExtendedKey.xprv)
        
        let db = DatabaseConfig.memory
        let electrum = ElectrumConfig(url: "ssl://electrum.blockstream.info:60002", socks5: nil, retry: 5, timeout: nil, stopGap: 10)
        let blockchainConfig = BlockchainConfig.electrum(config: electrum)
        do {
            let blockchain = try Blockchain(config: blockchainConfig)
            let wallet = try Wallet(descriptor: descriptor, changeDescriptor: changeDescriptor, network: Network.testnet, databaseConfig: db)
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

