//
//  RootViewViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import Foundation
import Combine

class RootViewViewModel: ObservableObject {
    @Published var hasAccount: Bool = false
    
    private var subscriptions = Set<AnyCancellable>()

    init() {
        hasAccount = Portal.shared.accountManager.activeAccount != nil
        
        Portal.shared.accountManager.onActiveAccountUpdate
            .receive(on: RunLoop.main)
            .sink { [unowned self] account in
                hasAccount = account != nil
            }
            .store(in: &subscriptions)
    }
}
