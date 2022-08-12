//
//  RootViewViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import Foundation
import Combine

class RootViewViewModel: ObservableObject {
    enum State {
        case account, empty
    }
    @Published var state: State = .empty
    
    private var subscriptions = Set<AnyCancellable>()

    init(accountManager: IAccountManager) {
        if accountManager.activeAccount != nil {
            state = .account
        }
        
        accountManager.onActiveAccountUpdate
            .receive(on: RunLoop.main)
            .sink { [unowned self] account in
                guard account != nil, state != .account else { return }
                state = .account
            }
            .store(in: &subscriptions)
    }
}

extension RootViewViewModel {
    static func config() -> RootViewViewModel {
        let manager = Portal.shared.accountManager
        return RootViewViewModel(accountManager: manager)
    }
}
