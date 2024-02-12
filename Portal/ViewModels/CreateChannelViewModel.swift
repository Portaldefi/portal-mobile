//
//  CreateChannelViewModel.swift
//  Portal
//
//  Created by farid on 20.12.2023.
//

import Foundation
import Factory
import Combine
import SwiftUI

@Observable class CreateChannelViewModel {
    private(set) var exchanger: Exchanger?
    private(set) var useAllFundsEnabled = true
    private(set) var balanceString = String()
    private(set) var valueString = String()
    private(set) var recomendedFees: RecomendedFees?
        
    private var marketData = Container.marketData()
    private var settings = Container.settings()
    
    @ObservationIgnored let peer: Peer
    @ObservationIgnored private var sendService: ISendAssetService?
    @ObservationIgnored private var subscriptions = Set<AnyCancellable>()
    
    private var lightningKit = Container.lightningKitManager()
    
    public var showFeesPicker = false
    
    public var amountIsValid: Bool = true
    public var coin: Coin = .bitcoin()
    public var feeRate: TxFees = .normal {
        didSet {
            sendService?.feeRateType.send(feeRate)
        }
    }
    
    var fee: String {
        guard let recomendedFees = recomendedFees, let sendService = sendService else { return String() }
        switch coin.type {
        case .bitcoin, .lightningBitcoin:
            return ((sendService.fee.double)/100_000_000).formattedString(.coin(coin), decimals: 8)
        case .ethereum, .erc20:
            return recomendedFees.fee(feeRate).double.formattedString(.coin(coin), decimals: 8)
        }
    }
    
    var showFees: Bool {
        guard let exchanger = exchanger, amountIsValid else {
            return false
        }
        return exchanger.baseAmountDecimal > 0 && sendService?.fee != 0
    }
    
    var fiatCurrency: FiatCurrency {
        settings.fiatCurrency.value
    }
    
    init(peer: Peer) {
        self.peer = peer
        
        let bitcoin: Coin = .bitcoin()
        
        syncSendService(coin: bitcoin)
        syncExchanger(coin: bitcoin)
    }
    
    private func syncExchanger(coin: Coin) {
        let price: Decimal = marketData.lastSeenBtcPrice
        
        exchanger = Exchanger(
            base: coin,
            quote: .fiat(fiatCurrency),
            price: price
        )
        
        guard let exchanger = exchanger, let sendService = self.sendService else { return }
        
        exchanger.$baseAmountDecimal
            .sink { [weak self] amount in
                guard let self = self else { return }
                
                withAnimation {
                    self.amountIsValid = amount <= sendService.spendable
                    self.useAllFundsEnabled = (amount != sendService.spendable)
                }
                
                guard self.amountIsValid, amount > 0, sendService.amount.value != amount else { return }
                sendService.amount.send(amount)
            }
            .store(in: &subscriptions)
    }
    
    private func syncSendService(coin: Coin) {
        let adapterManager: IAdapterManager = Container.adapterManager()

        guard
            let adapter = adapterManager.adapter(for: .bitcoin()),
            let sendAdapter = adapter as? ISendBitcoinAdapter
        else {
            fatalError("coudn't fetch dependencies")
        }

        sendService = SendBTCService(adapter: sendAdapter)
        
        if let service = sendService {
            balanceString = String(describing: service.spendable)
            valueString = (service.balance * marketData.lastSeenBtcPrice * fiatCurrency.rate).double.formattedString(.fiat(fiatCurrency))
        }
        
        sendService?.recomendedFees.sink { [weak self] fees in
            self?.recomendedFees = fees
        }
        .store(in: &subscriptions)
    }
                
    func validateInput() throws -> UserInputResult {
        guard let sendService = sendService else {
            throw SendFlowError.addressIsntValid
        }
        return try sendService.validateUserInput()
    }
    
    func useAllFunds() {
        guard let sendService = sendService, let exchanger = exchanger else { return }
        let spendable = sendService.spendable
        
        switch exchanger.side {
        case .base:
            exchanger.amount.string = String(describing: spendable)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) {
                let spendable = sendService.spendable
                exchanger.amount.string = String(describing: spendable)
            }
        case .quote:
            exchanger.amount.string = String(describing: spendable * exchanger.price)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) {
                let spendable = sendService.spendable
                exchanger.amount.string = String(describing: spendable * exchanger.price)
            }
        }
    }
    
    func openChannel() async throws {
        guard let exchanger = exchanger, let sats = UInt64(exactly: (exchanger.baseAmountDecimal * 100_000_000).double) else { return }
        
        print("channel sats value: \(sats)")
    
        try await lightningKit.openChannel(peer: peer, amount: sats)
        
        //Save node data
        let encoder = JSONEncoder()
        let nodeData = try? encoder.encode(peer)
        
        UserDefaults.standard.set(nodeData, forKey: "NodeToConnect")
    }
    
    func disconnetPeer() {
        do {
            try lightningKit.disconnectPeer(peer)
        } catch {
            print("Faild discoinnect peer: \(peer), error: \(error)")
        }
    }
}
