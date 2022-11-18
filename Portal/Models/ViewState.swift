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
        case activity
    }
    
    @Published var hideTabBar: Bool = false
    @Published var showQRCodeScannerFromTabBar: Bool = false {
        willSet {
            if newValue != showQRCodeScannerFromTabBar && newValue == false {
                Container.Scope.cached.reset()
            }
        }
    }
    @Published var goToSend: Bool = false {
        willSet {
            if newValue != goToSend && newValue == false {
                Container.Scope.cached.reset()
            }
        }
    }
    @Published var goToSendFromDetails: Bool = false {
        willSet {
            if newValue != goToSendFromDetails && newValue == false {
                Container.Scope.cached.reset()
            }
        }
    }
    @Published var showFeesPicker: Bool = false
    
    @Published var showInContextScanner = false
    @Published var goToReceive = false
    
    @Published private(set) var selectedTab: Tab = .wallet
    
    var onAssetBalancesUpdate = PassthroughSubject<Void, Never>()
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {}
    
    func openTab(_ tab: Tab) {
        selectedTab = tab
    }
}
