//
//  Portal+Injection.swift
//  BDKDemoApp
//
//  Created by farid on 25/8/22.
//

import Foundation
import Factory

extension SharedContainer {
    static let service = Factory<Portal>(scope: .singleton) { Portal() }
    static let accountViewModel = Factory<AccountViewModel>(scope: .singleton) { AccountViewModel() }
    static let viewState = Factory<ViewState>(scope: .singleton, factory: { ViewState() })
}
