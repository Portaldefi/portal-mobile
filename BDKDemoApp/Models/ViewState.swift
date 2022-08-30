//
//  ViewState.swift
//  BDKDemoApp
//
//  Created by farid on 23/8/22.
//

import Combine

class ViewState: ObservableObject {
    enum Tab: Int {
        case wallet = 0
        case activity
    }
    
    @Published var showScanner: Bool = false
    @Published private(set) var selectedTab: Tab = .wallet
    
    init() {}
    
    func openTab(_ tab: Tab) {
        selectedTab = tab
    }
}
