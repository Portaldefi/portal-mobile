//
//  WalletItem.swift
//  Portal
//
//  Created by farid on 7/20/22.
//

import Foundation
import SwiftUI
import PortalUI
import Factory
import Combine

struct WalletItem: Identifiable {
    let id: UUID = UUID()
    let viewModel: WalletItemViewModel
    
    var coin: Coin {
        viewModel.coin
    }
    
    var balanceUpdated: AnyPublisher<Void, Never> {
        viewModel.balanceAdapter.balanceUpdated
    }
    
    init(coin: Coin) {
        self.viewModel = WalletItemViewModel.config(coin: coin)
    }
}

extension WalletItem {
    static var mockedBtc: WalletItem {
        WalletItem(coin: .bitcoin())
    }
    
    static var mockedPortal: WalletItem {
        WalletItem(coin: .portal())
    }
    
    static var mocked: WalletItem {
        WalletItem(coin: .mocked())
    }
}
