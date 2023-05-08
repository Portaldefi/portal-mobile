//
//  AtomicSeekerTemplate.swift
//  Portal
//
//  Created by farid on 5/5/23.
//

import Foundation
import HsCryptoKit
import Factory

class AtomicSeekerTemplate: IAtomicSwap {
    private let ethereumKit: IAdapter & ISendEthereumAdapter
    private let lightningKit: ILightningInvoiceHandler & IBitcoinCore
    
    private var payDescriptor: String?
    
    var swap: Swap?
    var secretHash: String = "ignored"
    var id: String = "bob"
    
    init(ethereumKit: IAdapter & ISendEthereumAdapter, lightningKit: ILightningInvoiceHandler & IBitcoinCore) {
        self.ethereumKit = ethereumKit
        self.lightningKit = lightningKit
    }
    
    func open() async throws {
        guard let swap = swap else { return }

        print("[SWAP] Open in seeker atomic")
    }
    
    func commit() async throws {
//        guard let swap = swap else { return }

    }
    
    func cancel() async throws {
        
    }

}
