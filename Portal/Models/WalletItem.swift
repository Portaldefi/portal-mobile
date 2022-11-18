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

struct WalletItem: Identifiable {
    let id: UUID = UUID()
    let viewModel: WalletItemViewModel
}

extension WalletItem {
    static var mockedBtc: WalletItem {
        WalletItem(viewModel: WalletItemViewModel.mocked)
    }
}