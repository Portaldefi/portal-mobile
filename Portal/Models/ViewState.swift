//
//  ViewState.swift
//  Portal
//
//  Created by farid on 23/8/22.
//

import Combine
import Factory

class ViewState: ObservableObject {
    enum Tab: Int {
        case wallet = 0
        case swap
        case lightning
    }
    
    @Published var showSettings = false
    @Published var showBackUpFlow = false
    @Published var hideTabBar = false
    @Published var showQRCodeScannerFromTabBar: Bool = false {
        willSet {
            if newValue != showQRCodeScannerFromTabBar && newValue == false {
                Container.Scope.cached.reset()
            }
        }
    }    
    @Published private(set) var selectedTab: Tab = .wallet
    
    var onAssetBalancesUpdate = PassthroughSubject<Void, Never>()
        
    init() {}
    
    func openTab(_ tab: Tab) {
        selectedTab = tab
    }
}
