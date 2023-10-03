//
//  SubmarineSwapViewModel.swift
//  Portal
//
//  Created by farid on 4/24/23.
//

import Foundation
import Factory
import SwiftUI
import Combine

class SubmarineSwapViewModel: ObservableObject {
    enum SwapState {
        case new, create, matched, open, commit, swapped, canceled
    }
    
    private let coinRate: Decimal = pow(10, 8)

    @Published var orderSide: Order.OrderSide = .ask
    @Published var exchangerSide: Exchanger.Side = .base
    @Published var base: Coin? = .bitcoin()
    @Published var quote: Coin? = .bitcoin()
    @Published var baseAmount = "0.0005"
    @Published var quoteAmount = "0.0005"
    @Published var showPicker = false
    @Published var actionButtonEnabled = true
    @Published var bottomOffset: CGFloat = 65
    @Published var goToReview = false
    @Published var swapState: SwapState = .new
    @Published var order: Order?
    
    private var viewState = Container.viewState()
    
    private let bitcoinKit: IBalanceAdapter & ISendBitcoinAdapter
    private let lightningKit: ILightningChannels
    private let marketData: IMarketDataRepository
    private var subscriptions = Set<AnyCancellable>()
    
    private var client: SubmarineSwap?
        
    var description: String {
        switch orderSide {
        case .ask:
            return "[Secret holder]"
        case .bid:
            return "[Secret seeker]"
        }
    }
    
    var L1Balance: String {
        "\(bitcoinKit.L1Balance)"
    }
    
    var L2Balance: String {
        "\(lightningKit.channelBalance/1000/coinRate)"
    }
    
    var amountValue: String {
        return (marketData.lastSeenBtcPrice * 0.0005).double.usdFormatted()
    }
        
    init() {
        self.marketData = Container.marketData()
        let wallet = Container.walletManager().wallets.first!
        bitcoinKit = Container.adapterManager().adapter(for: wallet) as! IBalanceAdapter & ISendBitcoinAdapter
        lightningKit = Container.lightningKitManager()
    }
    
    func setupClient() {
        client = SubmarineSwap(side: orderSide)
        client?
            .onOrderUpdate
            .receive(on: RunLoop.main)
            .sink { [unowned self] order in
                self.order = order
            }
            .store(in: &subscriptions)
    }

    func submitLimitOrder() async throws {
        if client == nil {
            setupClient()
        }
        let updatedOrder = try await client?.submitLimitOrder()
        swapState = .create
        order = updatedOrder
    }
    
    func openSwap() async {
        withAnimation {
            swapState = .open
        }
        do {
            try await client?.open()
        } catch {
            print("[SWAP] Opening swap failed with error: \(error)")
            print("[SWAP] Description: \(error.localizedDescription)")
        }
    }
    
    func commitSwap() async {
        withAnimation {
            swapState = .commit
        }
        do {
            try await client?.commit()
            
            withAnimation {
                swapState = .swapped
            }
        } catch {
            print("[SWAP] Commiting swap failed with error: \(error)")
            print("[SWAP] Description: \(error.localizedDescription)")
        }
    }    
}
