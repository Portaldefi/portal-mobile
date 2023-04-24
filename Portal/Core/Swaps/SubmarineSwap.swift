//
//  SubmarineSwap.swift
//  Portal
//
//  Created by farid on 4/21/23.
//

import Foundation

class SubmarineSwap {
    var data: SwapInfo?
    private let swap: ISubmarineSwap
    
    init(data: SwapInfo? = nil, side: SwapSide) {
        self.data = data
        
        switch side {
        case .secretHolder:
            swap = HolderTemplate(data: data)
        case .secretSeeker:
            swap = SeekerTemplate(data: data)
        }
    }
    
    
    func open() async throws {
        try await swap.open()
    }
    
    func commit() async throws {
        try await swap.commit()
    }
    
    func cancel() async throws {
        try await swap.cancel()
    }
}
