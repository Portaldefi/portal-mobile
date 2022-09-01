//
//  AccountViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import Foundation
import BitcoinDevKit
import SwiftUI
import Factory

class AccountViewModel: ObservableObject {
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
    @Published private(set) var balance: String = "0"
    @Published private(set) var value: String = "0"
    @Published private(set) var transactions: [BitcoinDevKit.Transaction] = []
    @Published private(set) var items: [WalletItem] = []
    @Published private(set) var accountName = String()
    
    @Injected(Container.accountManager) private var manager
    
    private(set) var progressHandler = ProgressHandler()
    
    private let networkQueue = DispatchQueue(label: "com.portal.network.layer.queue", qos: .userInitiated)
    private let mocked: Bool
    
    init(mocked: Bool = false) {
        self.mocked = mocked
        if !mocked {
            setup()
            loadCache()
        }
    }
    
    private func setup() {
//        state = .loading
        
        guard let account = manager.activeAccount else {
            fatalError("\(#function): There is no account")
        }
        
        accountName = account.name
        
        let fingerprint = account.extendedKey.fingerprint
        let xprv = account.extendedKey.xprv
                
        let descriptor = "wpkh([\(fingerprint)/84'/0'/0']\(xprv)/*)"
        let changeDescriptor = "wpkh([\(fingerprint)/84'/0'/1']\(xprv)/*)"
        
        if let dbPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last?.absoluteString {
            let sqliteConfig = SqliteDbConfiguration(path: dbPath + "portal.sqlite" + "\(account.id)")
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
    
    private func loadCache() {
        guard case .loaded(let wallet, _) = state else { return }
        
        do {
            let _balance = try wallet.getBalance()
            balance = _balance.totalValueString(currency: .btc)
            let currency = FiatCurrency(code: "USD", name: "Dollar", rate: 0.0004563)
            value = (Double(_balance) * currency.rate).formattedString(.fiat(currency))
            
            let txs = try wallet.getTransactions().sorted(by: {
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
            
            transactions = txs
        } catch {
            state = State.failed(error)
        }
        
        items = [WalletItem(description: "on Chain", balance: balance, value: value)]
    }
    
    func sync() {
        guard !mocked else { return }
        
        setup()
        
        guard syncState != .syncing, case .loaded(let wallet, let blockchain) = state else { return }
        
        syncState = .syncing
        
        networkQueue.async {
            do {
                try wallet.sync(blockchain: blockchain, progress: self.progressHandler)
            } catch {
                DispatchQueue.main.async {
                    self.syncState = .failed(error)
                }
            }

            do {
                let txs = try wallet.getTransactions()

                let _Balance = try wallet.getBalance()
                let _balance = _Balance.totalValueString(currency: .btc)
                let currency = FiatCurrency(code: "USD", name: "Dollar", rate: 0.0004563)
                let _value = (Double(_Balance) * currency.rate).formattedString(.fiat(currency))
                let _items = [WalletItem(description: "on Chain", balance: _balance, value: _value)]

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
                    self.value = _value
                    self.transactions = _transactions
                }
            } catch {
                DispatchQueue.main.async {
                    self.state = .failed(error)
                }
            }
        }
    }
    
    func send(to: String, amount: String, completion: @escaping (Error?) -> Void) {
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
                        completion(nil)
                    }
                } else {
                    completion(SendError.insufficientAmount)
                }
            } catch {
                completion(error)
            }
        default:
            completion(SendError.error("Send error: wallet isn't loaded"))
        }
    }
    
    func getAddress(new: Bool = false) -> String {
        switch state {
        case .loaded(let wallet, _):
            do {
                let addressInfo = try wallet.getAddress(addressIndex: new ? AddressIndex.new : AddressIndex.lastUnused)
                print("======================================================")
                print("receive address: \(addressInfo.address)")
                print("======================================================")
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
}

extension AccountViewModel {
    static func mocked() -> AccountViewModel {
        let stringsArray = ["fiscal", "ribbon", "chief", "chest", "truly", "rough", "woman", "ugly", "opera", "language", "raccoon", "victory", "expose", "elder", "asthma", "curious", "special", "cactus", "train", "equip", "exchange", "artist", "journey", "dish"]
        let mnemonic = String(stringsArray.reduce(String(), { $0 + " " + $1}).dropFirst())
        let restoredExtendedKey = try! restoreExtendedKey(network: Network.testnet, mnemonic: mnemonic, password: "salty_password")
        let descriptor = "wpkh([\(restoredExtendedKey.fingerprint)/44'/0'/0']\(restoredExtendedKey.xprv)/*)"
        let changeDescriptor = "wpkh([\(restoredExtendedKey.fingerprint)/44'/0'/1']\(restoredExtendedKey.xprv)/*)"
        
        let wallet = try! Wallet(descriptor: descriptor, changeDescriptor: changeDescriptor, network: Network.testnet, databaseConfig: .memory)
        let electrum = ElectrumConfig(url: "ssl://electrum.blockstream.info:60002", socks5: nil, retry: 5, timeout: nil, stopGap: 10)
        let blockchainConfig = BlockchainConfig.electrum(config: electrum)
        let blockchain = try! Blockchain(config: blockchainConfig)
        let viewModel = AccountViewModel(mocked: true)
        viewModel.state = .loaded(wallet, blockchain)
        viewModel.syncState = .synced
        viewModel.balance = "23587"
        viewModel.accountName = "Test"
        viewModel.items = [WalletItem(description: "on Chain", balance: "23587", value: "$56"), WalletItem(description: "in Lightning", balance: "143255", value: "$156")]
        return viewModel
    }
}
