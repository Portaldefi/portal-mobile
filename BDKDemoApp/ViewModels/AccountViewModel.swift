//
//  AccountViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import Foundation
import BitcoinDevKit
import SwiftUI
import PortalUI
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
        case loaded(BitcoinDevKit.Wallet, Blockchain)
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
        
    @Published private(set) var state = State.empty
    @Published private(set) var syncState = SyncState.empty
    @Published private(set) var totalBalance: String = "0"
    @Published private(set) var assetBalance: String = "0"
    @Published private(set) var value: String = "0"
    @Published private(set) var transactions: [BitcoinDevKit.Transaction] = []
    @Published private(set) var items: [WalletItem] = []
    @Published private(set) var accountName = String()
    
    @Injected(Container.accountManager) private var manager
    @Injected(Container.marketData) private var marketData
    
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
        state = .loading
        
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
                let wallet = try BitcoinDevKit.Wallet(descriptor: descriptor, changeDescriptor: changeDescriptor, network: Network.testnet, databaseConfig: db)
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
            totalBalance = String(_balance).groupedByThree
            assetBalance = String(Double(_balance)/100_000_000)
            let usd = marketData.fiatCurrencies.first(where: { $0.code == "USD"}) ?? FiatCurrency(code: "USD", name: "Dollar", rate: 0.0004563)
            let btcPriceInUsd = marketData.btcTicker?[.usd].price ?? 1
            value = (Double(_balance) * (btcPriceInUsd.double/100_000_000)).formattedString(.fiat(usd))
            
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
        
        items = [
            WalletItem(
                icon: Asset.btcIcon,
                chainIcon: Asset.chainIcon,
                name: "Bitcoin",
                description: "Chain",
                balance: assetBalance,
                unit: "btc",
                value: value
            ),
            WalletItem(
                icon: Asset.btcIcon,
                chainIcon: Asset.lightningRounded,
                name: "Bitcoin",
                description: "Lightning",
                balance: "0",
                unit: "sats",
                value: "$0"
            ),
            WalletItem(
                icon: Asset.ethIcon,
                chainIcon: Asset.chainIcon,
                name: "Ethereum",
                description: "Chain",
                balance: "0",
                unit: "eth",
                value: "$0"
            )
        ]
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
                let _balance = String(_Balance).groupedByThree
                let _assetBalance = String(Double(_Balance)/100_000_000)
                let usd = self.marketData.fiatCurrencies.first(where: { $0.code == "USD"}) ?? FiatCurrency(code: "USD", name: "Dollar", rate: 0.0004563)
                let btcPriceInUsd = self.marketData.btcTicker?[.usd].price ?? 1
                let _value = (Double(_Balance) * (btcPriceInUsd.double / 100_000_000)).formattedString(.btc)
                let _items = [
                    WalletItem(
                        icon: Asset.btcIcon,
                        chainIcon: Asset.chainIcon,
                        name: "Bitcoin",
                        description: "Chain",
                        balance: _assetBalance,
                        unit: "btc",
                        value: _value
                    ),
                    WalletItem(
                        icon: Asset.btcIcon,
                        chainIcon: Asset.lightningRounded,
                        name: "Bitcoin",
                        description: "Lightning",
                        balance: "0",
                        unit: "sats",
                        value: "$0"
                    ),
                    WalletItem(
                        icon: Asset.ethIcon,
                        chainIcon: Asset.chainIcon,
                        name: "Ethereum",
                        description: "Chain",
                        balance: "0",
                        unit: "eth",
                        value: "$0"
                    )
                ]

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
                    self.totalBalance = _balance
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
                    completion(SendFlowError.insufficientAmount)
                }
            } catch {
                completion(error)
            }
        default:
            completion(SendFlowError.error("Send error: wallet isn't loaded"))
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
        
        let wallet = try! BitcoinDevKit.Wallet(descriptor: descriptor, changeDescriptor: changeDescriptor, network: Network.testnet, databaseConfig: .memory)
        let electrum = ElectrumConfig(url: "ssl://electrum.blockstream.info:60002", socks5: nil, retry: 5, timeout: nil, stopGap: 10)
        let blockchainConfig = BlockchainConfig.electrum(config: electrum)
        let blockchain = try! Blockchain(config: blockchainConfig)
        let viewModel = AccountViewModel(mocked: true)
        viewModel.state = .loaded(wallet, blockchain)
        viewModel.syncState = .synced
        viewModel.totalBalance = "23587"
        viewModel.accountName = "Test"
        viewModel.items = [
            WalletItem(icon: Asset.btcIcon, chainIcon: Asset.chainIcon, name: "Bitcoin", description: "Chain", balance: "23587", unit: "btc",  value: "$56"),
            WalletItem(icon: Asset.btcIcon, chainIcon: Asset.chainIcon, name: "Bitcoin", description: "Lightning", balance: "143255", unit: "btc", value: "$156")
        ]
        return viewModel
    }
}
