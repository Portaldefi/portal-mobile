//
//  HolderTemplate.swift
//  Portal
//
//  Created by farid on 4/21/23.
//

import Foundation
import Factory

class HolderTemplate: ISubmarineSwap {
    private let bitcoinKit: IBitcoinKitManager
    private let lightningKit: ILightningKitManager
    
    var data: SwapInfo?
    
    init(data: SwapInfo?) {
        self.data = data
        
        let wallet = Container.walletManager().activeWallets.first!
        let adapter = Container.adapterManager().adapter(for: wallet)!
        
        bitcoinKit = adapter as! IBitcoinKitManager
        lightningKit = Container.lightningKitManager()
    }
    
    func open() async throws {
        guard let swapData = data else { return }
        
        print("[SWAP] Open in holder submarine")
        
        let amount: UInt64 = 50000
        
        if let invoice = await lightningKit.createInvoice(paymentHash: swapData.hash, satAmount: amount) {
            print("[SWAP] secret holder lightning invoice: \(invoice)")
        }
    }
    
    func commit() async throws {
        guard let swapData = data else { return }

        let tx = try bitcoinKit.send(amount: 0.0005, address: swapData.seekerL1Address)
        print("[SWAP] Holder sent tx: \(tx.id)")
    }
    
    func cancel() async throws {
        
    }
}
