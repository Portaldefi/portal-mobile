//
//  ViewState.swift
//  Portal
//
//  Created by farid on 23/8/22.
//

import Combine
import Factory
import Foundation

class ViewState: ObservableObject {
    enum Tab: Int {
        case wallet = 0
//        case swap
        case lightning
        case activity
    }
    
    enum SceneState {
        case inactive, active, background
    }
    
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
    @Published var walletLocked = false
    @Published var sceneState: SceneState = .inactive
    
    @Injected(Container.settings) var settings
    
    var onAssetBalancesUpdate = PassthroughSubject<Void, Never>()
    
    private var subscriptions = Set<AnyCancellable>()
        
    init() {
        updateScene(state: .background)
    }
    
    func openTab(_ tab: Tab) {
        selectedTab = tab
    }
    
    func updateScene(state: SceneState) {
        switch state {
        case .background:
            print("app went to background state")
            
            guard sceneState != .background else { return }
            sceneState = .background
            
            walletLocked = settings.pincodeEnabled.value || settings.biometricsEnabled.value
        case .active:
            print("app went to active state")
            
            guard sceneState != .active else { return }
            
            sceneState = .active
        case .inactive:
            print("app went to inactive state")
        }
    }
}
