//
//  AccountViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import Foundation
import BitcoinDevKit
import SwiftUI

struct StringFormatter {
    static func localizedValueString(value: Decimal, symbol: String? = "$") -> String {
        let formatter = NumberFormatter()
        formatter.currencySymbol = symbol
        formatter.groupingSize = 3
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2 //value < 1 ? 2 : 0
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: value as NSDecimalNumber) ?? "#"
    }
    
    static func localizedValueString(value: Double, symbol: String? = "$") -> String {
        let formatter = NumberFormatter()
        formatter.currencySymbol = symbol
        formatter.groupingSize = 3
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2 //value < 1 ? 2 : 0
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "#"
    }
}

extension Double {
    func dollarFormatted() -> String {
        StringFormatter.localizedValueString(value: self, symbol: "$")
    }
    func btcFormatted() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
//        formatter.groupingSize = 3
//        formatter.numberStyle = .none
//        formatter.groupingSeparator = " "

//        formatter.minimumFractionDigits = 0
//        formatter.maximumFractionDigits = 18
        return String(formatter.string(from: number) ?? "")
//        roundToDecimal(6).toString()
    }
    func ethFormatted() -> String {
        roundToDecimal(6).toString() + " ETH"
    }
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
    func toString(decimal: Int = 12) -> String {
        let value = decimal < 0 ? 0 : decimal
        var string = String(format: "%.\(value)f", self)
        
        while string.last == "0" || string.last == "." {
            if string.last == "." { string = String(string.dropLast()); break }
            string = String(string.dropLast())
        }
        if string == "0" {
            string = "0.00"
        }
        return string
    }
    
    func fiatFormatted(_ symbol: String? = "$") -> String {
        let formatter = NumberFormatter()
        formatter.currencySymbol = symbol
        formatter.groupingSize = 3
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2 //self < 1 ? 2 : 0
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? "#"
    }
    
    func precisionString() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 18
        return String(formatter.string(from: number) ?? "")
    }
    
    func formattedString(_ currency: Currency, decimals: Int = 5) -> String {
        let formatter = NumberFormatter()

        switch currency {
        case .btc:
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = decimals
            formatter.minimumFractionDigits = 0
            formatter.minimumIntegerDigits = 1
            return (formatter.string(from: NSNumber(value: self)) ?? "-")
        case .eth:
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = decimals
            formatter.minimumFractionDigits = 0
            formatter.minimumIntegerDigits = 1
            return (formatter.string(from: NSNumber(value: self)) ?? "-") + " ETH"
        case .fiat(let fiatCurrency):
            formatter.currencySymbol = fiatCurrency.symbol
            formatter.groupingSize = 3
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            formatter.minimumIntegerDigits = 1
            return formatter.string(from: NSNumber(value: self)) ?? "-"
        }
    }
}

extension UInt64 {
    func formattedString(_ currency: Currency, decimals: Int = 0) -> String {
        let formatter = NumberFormatter()

        switch currency {
        case .btc:
            formatter.numberStyle = .none
            formatter.maximumFractionDigits = decimals
            formatter.minimumFractionDigits = 0
            formatter.minimumIntegerDigits = 1
            return (formatter.string(from: NSNumber(value: self)) ?? "-")
        case .eth:
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = decimals
            formatter.minimumFractionDigits = 0
            formatter.minimumIntegerDigits = 1
            return (formatter.string(from: NSNumber(value: self)) ?? "-") + " ETH"
        case .fiat(let fiatCurrency):
            formatter.currencySymbol = fiatCurrency.symbol
            formatter.groupingSize = 3
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 0
            formatter.minimumIntegerDigits = 1
            return formatter.string(from: NSNumber(value: self)) ?? "-"
        }
    }
    
    func localizedValueString(value: Double, symbol: String? = "$") -> String {
        let formatter = NumberFormatter()
        formatter.currencySymbol = symbol
        formatter.groupingSize = 3
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2 //value < 1 ? 2 : 0
        formatter.minimumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "#"
    }
    
    func totalValueString(currency: Currency) -> String {
        let double = Double(self)
        switch currency {
        case .btc:
            return double.btcFormatted()
        case .eth:
            return double.ethFormatted()
        case .fiat(let currency):
            return localizedValueString(value: double * currency.rate, symbol: currency.symbol)
        }
    }
}

struct FiatCurrency: Codable {
    let code: String
    let name: String
    let rate: Double
    
    var symbol: String {
        get {
            getSymbolForCurrencyCode(code: code) ?? "-"
        }
    }
    
    init(code: String, name: String, rate: Double = 1.0) {
        self.code = code
        self.name = name
        self.rate = rate
    }
    
    private func getSymbolForCurrencyCode(code: String) -> String? {
        var candidates: [String] = []
        let locales: [String] = NSLocale.availableLocaleIdentifiers
        for localeID in locales {
            guard let symbol = findMatchingSymbol(localeID: localeID, currencyCode: code) else {
                continue
            }
            if symbol.count == 1 {
                return symbol
            }
            candidates.append(symbol)
        }
        let sorted = sortAscByLength(list: candidates)
        if sorted.count < 1 {
            return nil
        }
        return sorted[0]
    }
    
    private func findMatchingSymbol(localeID: String, currencyCode: String) -> String? {
        let locale = Locale(identifier: localeID as String)
        guard let code = locale.currencyCode else {
            return nil
        }
        if code != currencyCode {
            return nil
        }
        guard let symbol = locale.currencySymbol else {
            return nil
        }
        return symbol
    }
    
    private func sortAscByLength(list: [String]) -> [String] {
        return list.sorted(by: { $0.count < $1.count })
    }
}


enum Currency: Equatable {
    static func == (lhs: Currency, rhs: Currency) -> Bool {
        lhs.symbol == rhs.symbol
    }
    
    case fiat(FiatCurrency)
    case btc
    case eth
    
    var symbol: String {
        switch self {
        case .fiat(let currency):
            return currency.symbol
        case .btc:
            return "₿"
        case .eth:
            return "Ξ"
        }
    }
    
    var code: String {
        switch self {
        case .fiat(let currency):
            return currency.code
        case .btc:
            return "BTC"
        case .eth:
            return "ETH"
        }
    }
    
    var name: String {
        switch self {
        case .fiat(let currency):
            return currency.name
        case .btc:
            return "Bitcoin"
        case .eth:
            return "Ethereum"
        }
    }
}

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
    
    private(set) var progressHandler = ProgressHandler()
    
    private let networkQueue = DispatchQueue(label: "com.portal.network.layer.queue", qos: .userInitiated)
    
    init() {
        setup()
        loadCache()
    }
    
    private func setup() {
//        state = .loading
        
        guard let account = Portal.shared.accountManager.activeAccount else {
            fatalError("\(#function): There is no account")
        }
        
        accountName = account.name
        
        let fingerprint = account.extendedKey.fingerprint
        let xprv = account.extendedKey.xprv
        
        let key = ExtendedKeyInfo(mnemonic: <#T##String#>, xprv: <#T##String#>, fingerprint: <#T##String#>)
        
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
        let viewModel = AccountViewModel()
        viewModel.balance = "23587"
        viewModel.items = [WalletItem(description: "on Chain", balance: "23587", value: "$56"), WalletItem(description: "in Lightning", balance: "143255", value: "$156")]
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

