//
//  ViewState.swift
//  Portal
//
//  Created by farid on 23/8/22.
//

import Combine
import Factory
import Foundation

@Observable class ViewState {
    enum Tab: Int {
        case wallet = 0
//        case swap
        case lightning
        case activity
    }
    
    enum SceneState {
        case inactive, active, background
    }
    
    public var showBackUpFlow = false
    public var hideTabBar = false
    public var showQRCodeScannerFromTabBar: Bool = false {
        willSet {
            if newValue != showQRCodeScannerFromTabBar && newValue == false {
                Container.Scope.cached.reset()
            }
        }
    }
    private(set) var selectedTab: Tab = .wallet
    public private(set) var isReachable = false
    public var walletLocked = false
    
    @ObservationIgnored private(set) var sceneState: SceneState = .inactive {
        didSet {
            onSceneStateChange.send(sceneState)
        }
    }
        
    @ObservationIgnored private var settings = Container.settings()
    @ObservationIgnored private var reachability = Container.reachabilityService()
    @ObservationIgnored private var subscriptions = Set<AnyCancellable>()
    
    @ObservationIgnored public var onAssetBalancesUpdate = PassthroughSubject<Void, Never>()
    @ObservationIgnored public var onSceneStateChange = PassthroughSubject<SceneState, Never>()
        
    init() {
        updateScene(state: .background)
        reachability.startMonitoring()
        
        isReachable = reachability.isReachable.value
        
        reachability.isReachable.receive(on: DispatchQueue.main).sink { reachable in
            print("Network is \(reachable ? "reachable" : "not reachable")")
            self.isReachable = reachable
        }
        .store(in: &subscriptions)
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

extension ViewState {
    static func mocked(hasConnection: Bool) -> ViewState {
        let _ = Container.reachabilityService.register { ReachabilityService.mocked(hasConnection: hasConnection) }
        
        return ViewState()
    }
}
