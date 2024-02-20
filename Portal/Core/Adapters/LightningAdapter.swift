//
//  LightningAdapter.swift
//  Portal
//
//  Created by farid on 07.12.2023.
//

import Foundation
import Combine
import LightningDevKit
import Lightning

final class LightningAdapter {
    private let txDataStorage: ITxUserDataStorage
    private let notificationService: INotificationService

    private let coinRate: Decimal = pow(10, 8)
    private let manager: ILightningKitManager
    private let updateTimer = RepeatingTimer(timeInterval: 5)
    private let stateUpdatedSubject = PassthroughSubject<Void, Never>()
    private let balanceUpdatedSubject = PassthroughSubject<Void, Never>()
    private var _channelBalance: Decimal = 0
    
    private var adapterState: AdapterState = .synced
    
    init(wallet: Wallet, manager: ILightningKitManager, txDataStorage: ITxUserDataStorage, notificationService: INotificationService) {
        self.manager = manager
        self.txDataStorage = txDataStorage
        self.notificationService = notificationService
        
        updateTimer.eventHandler = { [unowned self] in
            self.syncData()
        }
    }
    
    private func syncData() {
        guard _channelBalance != channelBalance else { return }
        _channelBalance = channelBalance
        balanceUpdatedSubject.send()
        
        let transactions = manager.transactions
        
        for transaction in transactions {
            guard
                lastKnownTxTimestamp > 0,
                transaction.type == .received,
                transaction.timestamp > lastKnownTxTimestamp
            else { continue }
            
            let satAmount = transaction.amount
            let btcAmount = satAmount / 100_000_000
            let message = "You've received \(btcAmount.formatted()) BTC"
            
            notificationService.sendLocalNotification(
                title: "Received BTC (Lightning)",
                body: message
            )
        }
        
        if
            let mostRecentTxTimestamp = transactions.map({ $0.timestamp }).max(),
            mostRecentTxTimestamp > lastKnownTxTimestamp
        {
            UserDefaults.standard.setValue(mostRecentTxTimestamp, forKey: "knownTxTimestamp.btc.lightning")
        }
    }
}

extension LightningAdapter: IAdapter {
    func start() {
        updateTimer.resume()
        
        Task {
            try await manager.start()
        }
    }
    
    func stop() {
        //TODO: - implement stop
        updateTimer.suspend()
    }
    
    func refresh() {
        //TODO: - implement refresh
    }
    
    var blockchainHeight: Int32 {
        manager.bestBlock
    }
}

extension LightningAdapter: IBalanceAdapter {
    var state: AdapterState {
        adapterState
    }
    
    var balance: Decimal {
        manager.channelBalance/1000/coinRate
    }
    
    var balanceStateUpdated: AnyPublisher<Void, Never> {
        stateUpdatedSubject.eraseToAnyPublisher()
    }
    
    var balanceUpdated: AnyPublisher<Void, Never> {
        balanceUpdatedSubject.eraseToAnyPublisher()
    }
}

extension LightningAdapter: ITransactionsAdapter {
    var lastKnownTxTimestamp: Int {
        UserDefaults.standard.integer(forKey: "knownTxTimestamp.btc.lightning")
    }
    
    var transactionRecords: [TransactionRecord] {
        manager.transactions.map { payment in
            let data = txDataStorage.fetch(source: .lightning, id: payment.paymentId)
            let userData = TxUserData(data: data)
            return LNTransactionRecord(payment: payment, userData: userData)
        }
        .sorted(by: { $0.timestamp ?? 1 > $1.timestamp ?? 0 })
    }
    
    var onTxsUpdate: AnyPublisher<Void, Never> {
        balanceUpdated
    }
}

extension LightningAdapter: ISendLightningAdapter {
    var spendable: Decimal {
        manager.channelBalance/1000/coinRate
    }
    
    func createInvoice(amount: String, description: String) async -> String? {
        await manager.createInvoice(amount: amount, description: description)
    }
    
    func decode(invoice: String) throws -> Bolt11Invoice {
        try manager.decode(invoice: invoice)
    }
    
    func pay(invoice: String) async throws -> TransactionRecord {
        let decodedInvoice = try manager.decode(invoice: invoice)
        let payment = try await manager.pay(invoice: decodedInvoice)
        let data = txDataStorage.fetch(source: .lightning, id: payment.paymentId)
        let userData = TxUserData(data: data)
        return LNTransactionRecord(payment: payment, userData: userData)
    }
}

extension LightningAdapter: ILightningChannels {
    func openChannel(peer: Peer, amount: UInt64) async throws {
        try await manager.openChannel(peer: peer, amount: amount)
    }
    
    var allChannels: [LightningDevKit.ChannelDetails] {
        manager.allChannels
    }
    
    var usableChannels: [LightningDevKit.ChannelDetails] {
        manager.usableChannels
    }
    
    var channelBalance: Decimal {
        manager.channelBalance
    }
    
    func cooperativeCloseChannel(id: [UInt8], counterPartyId: [UInt8]) {
        manager.cooperativeCloseChannel(id: id, counterPartyId: counterPartyId)
    }
    
    func forceCloseChannel(id: [UInt8], counterPartyId: [UInt8]) {
        manager.forceCloseChannel(id: id, counterPartyId: counterPartyId)
    }
}
