//
//  TransactionDetailsViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 10/2/22.
//

import Foundation
import Combine
import BitcoinDevKit
import Factory

class TransactionDetailsViewModel: ObservableObject {
    let storage: UserDefaults
    
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
    @Published var showAddLabelInterface = false
    @Published var newLabelTitle: String?
    
    @LazyInjected(Container.viewState) var viewState: ViewState
    
    var title: String {
        details.sent > 0 ? "Sent" : "Recieved"
    }
    
    var amountString: String {
        switch txSide {
        case .sent:
            return (Double(details.sent)/100_000_000).toString(decimal: 8)
        case .recieved:
            return (Double(details.received)/100_000_000).toString(decimal: 8)
        }
    }
    
    var currencyAmountString: String {
        "1.29"
    }
    
    var recipientString: String? {
        storage.object(forKey: details.txid + "recipient") as? String
    }
    
    var dateString: String {
        guard let blockTime = blockTime else {
            return Date().extendedDate()
        }
        
        return Date(timeIntervalSince1970: TimeInterval(blockTime.timestamp)).extendedDate()
    }
    
    var feeString: String {
        guard let fee = details.fee else { return "0.000000141" }
        return String(format: "%.8f", Double(fee)/100_000_000)
    }
        
    var txIdString: String {
        "\(details.txid.prefix(4))...\(details.txid.suffix(4))"
    }
    
    @Published var confirmations: Int = 0
    
    @Published var notes = String()
    @Published var labels: [TxLable] = []
    
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
    
    private var url: URL? = URL(string: "https://api.blockcypher.com/v1/btc/test3")
    private var urlSession: URLSession!
    private var subscriptions = Set<AnyCancellable>()
    
    init(coin: Coin, tx: BitcoinDevKit.Transaction) {
        self.coin = coin
        self.storage = UserDefaults.standard
                
        switch tx {
        case .confirmed(let details, let confirmations):
            self.details = details
            self.blockTime = confirmations
        case .unconfirmed(let details):
            self.details = details
            self.blockTime = nil
        }
        
        if let notes = storage.string(forKey: details.txid + "notes") {
            self.notes = notes
        }
        
        if let tags = storage.object(forKey: details.txid + "labels") as? [String] {
            self.labels = tags.map{ TxLable(label: $0 )}
        }

        updateChainTip()
        
        if let confirmatinos = storage.object(forKey: details.txid + "confirmations") as? Int {
            self.confirmations = confirmatinos
        }
        
        $labels.sink { labels in
            self.storage.set(labels.map{ $0.label }, forKey: self.details.txid + "labels")
        }
        .store(in: &subscriptions)
        
        $notes.sink { notes in
            self.storage.set(notes, forKey: self.details.txid + "notes")
        }
        .store(in: &subscriptions)
    }
    
    private func updateChainTip() {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        
        self.urlSession = URLSession(configuration: config)
        
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
                self?.updateConfirmations()
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)
    }
    
    private func updateConfirmations() {
        guard let blockTime = blockTime, currentBlockHeight > 0 else {
            return
        }
        self.confirmations = currentBlockHeight - Int(blockTime.height) + 1
        storage.set(confirmations, forKey: details.txid + "confirmations")
    }
}

extension TransactionDetailsViewModel {
    static func config(coin: Coin, tx: BitcoinDevKit.Transaction) -> TransactionDetailsViewModel {
        TransactionDetailsViewModel(coin: coin, tx: tx)
    }
}

