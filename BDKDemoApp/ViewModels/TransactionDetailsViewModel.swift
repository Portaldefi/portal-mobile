//
//  TransactionDetailsViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 10/2/22.
//

import Foundation
import Combine
import BitcoinDevKit

class TransactionDetailsViewModel: ObservableObject {
    struct TestNetDataResponse: Codable {
        let height: Int
    }
    
    enum TxSide {
        case sent, recieved
    }
    
    let coin: Coin
    let details: TransactionDetails
    let blockTime: BlockTime?
    
    @Published var editingNotes = false
    @Published var editingLabels = false
    
    var title: String {
        details.sent > 0 ? "Sent" : "Recieved"
    }
    
    var amountString: String {
        switch txSide {
        case .sent:
            return "\(Double(details.sent)/100_000_000)"
        case .recieved:
            return "\(Double(details.received)/100_000_000)"
        }
    }
    
    var currencyAmountString: String {
        "1.29"
    }
    
    var recipientString: String {
        "bc1q...zsx1"
    }
    
    var dateString: String {
        guard let blockTime = blockTime else {
            return String()
        }
        
        return Date(timeIntervalSince1970: TimeInterval(blockTime.timestamp)).extendedDate()
    }
    
    var feeString: String {
        guard let fee = details.fee else { return "-" }
        return String(format: "%.8f", Double(fee)/100_000_000)
    }
    
    var txIdString: String {
        "\(details.txid.prefix(4))...\(details.txid.suffix(4))"
    }
    
    var confirmations: Int {
        guard let blockTime = blockTime, currentBlockHeight > 0 else {
            return 0
        }
        return currentBlockHeight - Int(blockTime.height)
    }
    
    @Published var notes = String()
    
    var labels: [TxLable] {
        []/*[
            TxLable(label: "Taxes"),
            TxLable(label: "Buisness"),
            TxLable(label: "Friend"),
            TxLable(label: "Do Not Spend"),
            TxLable(label: "Savings"),
            TxLable(label: "Food")
        ]*/
    }
    
    var explorerUrl: URL? {
        switch coin.type {
        case .bitcoin:
            return URL(string: "https://blockstream.info/testnet/tx/\(details.txid)")
        case .ethereum:
            return URL(string: "https://ropsten.etherscan.io/tx/\(details.txid)")
        default:
            return nil
        }
    }
    
    private var txSide: TxSide {
        details.sent > 0 ? .sent : .recieved
    }
    
    private var currentBlockHeight = 0
    
    private var url: URL?
    private var urlSession: URLSession
    private var subscriptions = Set<AnyCancellable>()
    
    init(coin: Coin, tx: BitcoinDevKit.Transaction) {
        self.coin = coin
        
        switch tx {
        case .confirmed(let details, let confirmations):
            self.details = details
            self.blockTime = confirmations
        case .unconfirmed(let details):
            self.details = details
            self.blockTime = nil
        }
        
        self.url = URL(string: "https://api.blockcypher.com/v1/btc/test3")
        
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        
        self.urlSession = URLSession(configuration: config)
        updateChainTip()
    }
    
    private func updateChainTip() {
        guard let url = self.url else { return }
        
        urlSession.dataTaskPublisher(for: url)
            .tryMap { $0.data }
            .decode(type: TestNetDataResponse.self, decoder: JSONDecoder())
            .receive(on: RunLoop.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    print(error.localizedDescription)
                }
            } receiveValue: { [weak self] response in
                self?.currentBlockHeight = response.height
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)
    }
}

extension TransactionDetailsViewModel {
    static func config(coin: Coin, tx: BitcoinDevKit.Transaction) -> TransactionDetailsViewModel {
        TransactionDetailsViewModel(coin: coin, tx: tx)
    }
}

