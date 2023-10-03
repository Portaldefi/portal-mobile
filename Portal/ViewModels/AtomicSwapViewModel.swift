//
//  AtomicSwapViewModel.swift
//  Portal
//
//  Created by farid on 5/5/23.
//

import Foundation
import Factory
import SwiftUI
import Combine

class AtomicSwapViewModel: ObservableObject {
    enum SwapState {
        case create, matching, matched, open, commit, commiting, commited, canceled
    }
    
    private let coinRate: Decimal = pow(10, 8)

    @Published var orderSide: Order.OrderSide = .ask
    @Published var exchangerSide: Exchanger.Side = .base
    @Published var base: Coin? = .ethereum()
    @Published var quote: Coin? = .bitcoin()
    @Published var baseAmount = "0.0"
    @Published var quoteAmount = "0.0"
    @Published var showPicker = false
    @Published var actionButtonEnabled = true
    @Published var bottomOffset: CGFloat = 65
    @Published var goToReview = false
    @Published var swapState: SwapState = .create
    @Published var order: Order?
    
    private var viewState = Container.viewState()
    
    private let ethereumKit: IBalanceAdapter & ISendEthereumAdapter
    private let lightningKit: ILightningChannels
    private let marketData: IMarketDataRepository
    private var subscriptions = Set<AnyCancellable>()
    
    private var client: AtomicSwap?
        
    var description: String {
        switch orderSide {
        case .ask:
            return "[Secret holder]"
        case .bid:
            return "[Secret seeker]"
        }
    }
    
    var L1Balance: String {
        "\(ethereumKit.L1Balance)"
    }
    
    var L2Balance: String {
        "\(lightningKit.channelBalance/1000/coinRate)"
    }
    
    var baseAmountValue: String {
        let decimal = Decimal(string: baseAmount) ?? 0
        return (marketData.lastSeenEthPrice * decimal).double.usdFormatted()
    }
    
    var quoteAmountValue: String {
        let decimal = Decimal(string: quoteAmount) ?? 0
        return (marketData.lastSeenBtcPrice * decimal).double.usdFormatted()
    }
        
    init() {
        self.marketData = Container.marketData()
        let wallet = Container.walletManager().wallets.last!
        ethereumKit = Container.adapterManager().adapter(for: wallet) as! IBalanceAdapter & ISendEthereumAdapter
        lightningKit = Container.lightningKitManager()
    }
    
    func setupClient() {
        client = AtomicSwap(side: orderSide)
        
        client?
            .onOrderUpdate
            .receive(on: RunLoop.main)
            .sink { [unowned self] order in
                self.order = order
            }
            .store(in: &subscriptions)
        
        client?.onSwapUpdate
            .receive(on: RunLoop.main)
            .sink { [unowned self] swap in
                if swapState == .matching {
                    swapState = .matched
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.swapState = .open
                    }
                }
            }
            .store(in: &subscriptions)
    }

    func submitLimitOrder() async throws {
        if client == nil {
            setupClient()
        }
        let updatedOrder = try await client?.submitLimitOrder(baseQuantity: baseAmount, quoteQuantity: quoteAmount)
        swapState = .matching
        order = updatedOrder
    }
    
    func openSwap() async {
        do {
            try await client?.open()
            withAnimation {
                swapState = .commit
            }
        } catch {
            print("[SWAP] Opening swap failed with error: \(error)")
            print("[SWAP] Description: \(error.localizedDescription)")
        }
    }
    
    func commitSwap() async {
        do {
            try await client?.commit()
            
            withAnimation {
                swapState = .commiting
            }
        } catch {
            print("[SWAP] Commiting swap failed with error: \(error)")
            print("[SWAP] Description: \(error.localizedDescription)")
        }
    }
}

