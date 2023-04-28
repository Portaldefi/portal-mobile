//
//  SwapViewViewModel.swift
//  Portal
//
//  Created by farid on 4/24/23.
//

import Foundation
import Factory
import SwiftUI

class SwapViewViewModel: ObservableObject {
    enum SwapState {
        case opened, swapping, commiting, swapped, canceled
    }
    
    private let coinRate: Decimal = pow(10, 8)

    @Published var swapSide: SwapSide = .secretHolder
    @Published var base: Coin? = .bitcoin()
    @Published var quote: Coin? = .bitcoin()
    @Published var baseAmount = "0.0005"
    @Published var quoteAmount = "0.0005"
    @Published var showPicker = false
    @Published var actionButtonEnabled = true
    @Published var bottomOffset: CGFloat = 65
    @Published var goToReview = false
    @Published var swapState: SwapState = .opened
    
    @ObservedObject var viewState = Container.viewState()
    
    private let bitcoinKit: IBitcoinKitManager
    private let lightningKit: ILightningKitManager
    private let marketData: IMarketDataRepository
    
    private let swap: SubmarineSwap
    
    var description: String {
        switch swapSide {
        case .secretHolder:
            return "[Secret holder]"
        case .secretSeeker:
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
        guard let btcUSDPrice = marketData.btcTicker?.price else { return "" }
        return (Decimal(btcUSDPrice) * 0.0005).double.usdFormatted()
    }
    
    init() {
        self.marketData = Container.marketData()
        let wallet = Container.walletManager().wallets.first!
        bitcoinKit = Container.adapterManager().adapter(for: wallet) as! IBitcoinKitManager
        lightningKit = Container.lightningKitManager()
        
        let swapInfo = SwapInfo.mocked
        
        if swapInfo.holderPubKey == bitcoinKit.pubKey {
            swap = SubmarineSwap(data: swapInfo, side: .secretHolder)
            swapSide = .secretHolder
        } else {
            swap = SubmarineSwap(data: swapInfo, side: .secretSeeker)
            swapSide = .secretSeeker
        }
    }
    
    func openSwap() async {
        withAnimation {
            swapState = .swapping
        }
        do {
            try await swap.open()
        } catch {
            print("[SWAP] Opening swap failed with error: \(error)")
            print("[SWAP] Description: \(error.localizedDescription)")
        }
    }
    
    func commitSwap() async {
        withAnimation {
            swapState = .commiting
        }
        do {
            try await swap.commit()
            
            withAnimation {
                swapState = .swapped
            }
        } catch {
            print("[SWAP] Commiting swap failed with error: \(error)")
            print("[SWAP] Description: \(error.localizedDescription)")
        }
    }
}
