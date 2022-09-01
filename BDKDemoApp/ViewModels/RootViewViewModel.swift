//
//  RootViewViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import Foundation
import Combine
import Factory

class RootViewViewModel: ObservableObject {
    enum State {
        case account, empty
    }
    @Published var state: State = .empty
    
    private var subscriptions = Set<AnyCancellable>()
    @Injected(Container.accountManager) private var manager

    init() {
        if manager.activeAccount != nil {
            state = .account
        }
        
        manager.onActiveAccountUpdate
            .receive(on: RunLoop.main)
            .sink { [unowned self] account in
                guard account != nil, state != .account else { return }
                state = .account
            }
            .store(in: &subscriptions)
    }
}
