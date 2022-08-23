//
//  ViewState.swift
//  BDKDemoApp
//
//  Created by farid on 23/8/22.
//

import Combine

class ViewState: ObservableObject {
    @Published var showScanner: Bool = false
    
    init() {}
}
