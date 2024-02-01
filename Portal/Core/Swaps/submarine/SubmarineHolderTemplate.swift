//
//  SubmarineHolderTemplate.swift
//  Portal
//
//  Created by farid on 4/21/23.
//

import Foundation
import Factory
import HsCryptoKit
import PortalSwapSDK

class SubmarineHolderTemplate: ISubmarineSwap {
    private let bitcoinKit: ISendBitcoinAdapter
    private let lightningKit: ILightningInvoiceHandler
    
    var swap: SwapModel?
    var hash: String
    var id: String = "alice"
    
    init(bitcoinKit: ISendBitcoinAdapter, lightningKit: ILightningInvoiceHandler) {
        self.bitcoinKit = bitcoinKit
        self.lightningKit = lightningKit
        
        var randomBytes = [UInt8](repeating: 0, count: 32)
        _ = randomBytes.withUnsafeMutableBufferPointer { bufferPointer in
            SecRandomCopyBytes(kSecRandomDefault, 32, bufferPointer.baseAddress!)
        }
        
        let secret = randomBytes
        let secretData = Data(hex: secret.toHexString())
        let secretHash = Crypto.sha256(secretData).toHexString()
        
        print("[SWAP] secret holder secret hash: \(secretHash)")
        
        hash = secretHash
    }
    
    func open() async throws {
        guard let swap = swap else { return }
        
        print("[SWAP] Open in holder submarine")
                
//        if let invoice = await lightningKit.createInvoice(paymentHash: swap.secretHash, satAmount: UInt64(swap.secretHolder.quantity)) {
//            print("[SWAP] secret holder lightning invoice: \(invoice)")
//        }
    }
    
    func commit() async throws {
        guard let swap = swap else { return }

//        let tx = try bitcoinKit.send(amount: Decimal(swap.secretSeeker.quantity), address: "swap.secretSeeker")
//        print("[SWAP] Holder sent tx: \(tx.id)")
    }
    
    func cancel() async throws {
        
    }
}
