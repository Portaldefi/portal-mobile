//
//  WalletViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import Foundation
import BitcoinDevKit
import SwiftUI

class WalletViewModel: ObservableObject {
    class ProgressHandler: BitcoinDevKit.Progress {
        func update(progress: Float, message: String?) {
            print("progress: \(progress), message: \(message ?? "-")")
        }
    }
    
    enum State {
        case dbNotFound
        case empty
        case loading
        case failed(Error)
        case loaded(Wallet, Blockchain)
    }
    
    enum SyncState: Equatable {
        case empty
        case syncing
        case synced
        case failed(Error)
        
        static func ==(lhs: SyncState, rhs: SyncState) -> Bool {
            switch (lhs, rhs) {
            case (.empty, .empty),(.syncing, .syncing), (.synced, .synced), (.failed, .failed) : return true
            default: return false
            }
        }
    }
    
    enum SendError: Error {
        case insufficientAmount
        case error(String)
    }
    
    private(set) var key = "private_key"
    
    @Published private(set) var state = State.empty
    @Published private(set) var syncState = SyncState.empty
    @Published private(set) var balance: UInt64 = 0
    @Published private(set) var transactions: [BitcoinDevKit.Transaction] = []
    @Published private(set) var items: [WalletItem] = []
    
    private(set) var progressHandler = ProgressHandler()
    
    init() {
        load()
    }
    
    private func load() {
        state = .loading
        
        let stringsArray = ["fiscal", "ribbon", "chief", "chest", "truly", "rough", "woman", "ugly", "opera", "language", "raccoon", "victory", "expose", "elder", "asthma", "curious", "special", "cactus", "train", "equip", "exchange", "artist", "journey", "dish"]
        let mnemonic = String(stringsArray.reduce(String(), { $0 + " " + $1}).dropFirst())
        let restoredExtendedKey = try! restoreExtendedKey(network: Network.testnet, mnemonic: mnemonic, password: "salty_password")
        let descriptor = "wpkh([\(restoredExtendedKey.fingerprint)/84'/0'/0']\(restoredExtendedKey.xprv)/*)"
        let changeDescriptor = "wpkh([\(restoredExtendedKey.fingerprint)/84'/0'/1']\(restoredExtendedKey.xprv)/*)"
        
        print(restoredExtendedKey.mnemonic)
        print(restoredExtendedKey.xprv)
        
        if let dbPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last?.absoluteString {
            let sqliteConfig = SqliteDbConfiguration(path: dbPath + "portal.sqlite")
            let db = DatabaseConfig.sqlite(config: sqliteConfig)
            let electrum = ElectrumConfig(url: "ssl://electrum.blockstream.info:60002", socks5: nil, retry: 5, timeout: nil, stopGap: 10)
            let blockchainConfig = BlockchainConfig.electrum(config: electrum)
            do {
                let blockchain = try Blockchain(config: blockchainConfig)
                let wallet = try Wallet(descriptor: descriptor, changeDescriptor: changeDescriptor, network: Network.testnet, databaseConfig: db)
                state = State.loaded(wallet, blockchain)
            } catch let error {
                state = State.failed(error)
            }
        } else {
            state = State.dbNotFound
        }
    }
    
    func sync() {
        guard case .loaded(let wallet, let blockchain) = state else { return }
        
        syncState = .syncing
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try wallet.sync(blockchain: blockchain, progress: self.progressHandler)
                let txs = try wallet.getTransactions()

                let _balance = try wallet.getBalance()
                let _items = [WalletItem(description: "on Chain", balance: _balance)]

                let _transactions = txs.sorted(by: {
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

                DispatchQueue.main.async {
                    self.syncState = .synced
                    self.balance = _balance
                    self.items = _items
                    self.transactions = _transactions
                }
            } catch {
                print(error)
                self.syncState = .failed(error)
            }
        }
    }
    
    func send(to: String, amount: String) throws {
        switch state {
        case .loaded(let wallet, let blockchain):
            do {
                let walletBalance = try wallet.getBalance()
                if let amountToSend = UInt64(amount), walletBalance > amountToSend {
                    let psbt = try TxBuilder().addRecipient(address: to, amount: amountToSend).enableRbf().finish(wallet: wallet)
                    let finalized = try wallet.sign(psbt: psbt)
                    if finalized {
                        print("Tx id: \(psbt.txid())")
                        try blockchain.broadcast(psbt: psbt)
                        sync()
                    }
                } else {
                    throw SendError.insufficientAmount
                }
            } catch {
                throw error
            }
        default:
            throw SendError.error("Send error: wallet isn't loaded")
        }
    }
        
    func getAddress(new: Bool = false) -> String {
        switch state {
        case .loaded(let wallet, _):
            do {
                let addressInfo = try wallet.getAddress(addressIndex: new ? AddressIndex.new : AddressIndex.lastUnused)
                return addressInfo.address
            } catch {
                return "ERROR"
            }
        default:
            return "ERROR"
        }
    }
    
    func generateQRCode(from string: String) -> UIImage {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    static func mocked() -> WalletViewModel {
        let viewModel = WalletViewModel()
        viewModel.balance = 23587
        viewModel.items = [WalletItem(description: "on Chain", balance: 23587), WalletItem(description: "in Lightning", balance: 143255)]
        return viewModel
    }
}

extension Date {
    func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}

