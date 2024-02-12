//
//  RootViewViewModel.swift
// Portal
//
//  Created by farid on 8/9/22.
//

import Foundation
import Combine
import Factory

@Observable class RootViewViewModel {
    enum State {
        case account, empty
    }
    public var state: State = .empty
    
    @ObservationIgnored private var subscriptions = Set<AnyCancellable>()
    @ObservationIgnored private var manager = Container.accountManager()
    @ObservationIgnored private var settings = Container.settings()

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
