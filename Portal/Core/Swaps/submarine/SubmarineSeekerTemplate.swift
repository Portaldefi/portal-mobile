//
//  SubmarineSeekerTemplate.swift
//  Portal
//
//  Created by farid on 4/21/23.
//

import Foundation
import HsCryptoKit
import Factory
import PortalSwapSDK

class SubmarineSeekerTemplate: ISubmarineSwap {
    private let RELATIVE_SWAP_TIMELOCK: Int32 = 36
    private let RELATIVE_PAYMENT_DEADLINE: Int32 = 24
    private let REQUIRED_CONFIRMATIONS: Int32 = 3
    private let DEFAULT_MINER_FEE = 200
    
    private let bitcoinKit: IAdapter & ISendBitcoinAdapter
    private let lightningKit: ILightningInvoiceHandler & IBitcoinCore
    
    private var payDescriptor: String?
    
    var swap: SwapModel?
    var hash: String = "ignored"
    var id: String = "bob"
    
    init(bitcoinKit: IAdapter & ISendBitcoinAdapter, lightningKit: ILightningInvoiceHandler & IBitcoinCore) {
        self.bitcoinKit = bitcoinKit
        self.lightningKit = lightningKit
    }
    
    func open() async throws {
        guard let swap = swap else { return }

        print("[SWAP] Open in seeker submarine")

        let blockchainHeight: Int32 = 0//bitcoinKit.blockchainHeight
        let secretSeekerPublicKey = "bitcoinKit.pubKey"
        print("[SWAP] seeker pubKey: \(secretSeekerPublicKey)")
        let secretHolderPublicKey = ""//swap.secretSeeker.pubKey
        print("[SWAP] holder pubKey: \(secretHolderPublicKey)")
        let swapHash = swap.swapId
        let timelock = blockchainHeight + RELATIVE_SWAP_TIMELOCK
        print("[SWAP] timelock: \(timelock)")

        let witnessScript = scriptGenerator(
            secretSeekerPublicKey: secretSeekerPublicKey,
            secretHolderPublicKey: secretHolderPublicKey,
            swapHash: swapHash ?? "",
            timelock: timelock
        )

        print("[SWAP] witness script: \(witnessScript.toHexString())")

        guard let decodedAddress = await lightningKit.decodeAddress(outputScript: witnessScript) else {
            return
        }

        print("[SWAP] Decoded address: \(decodedAddress)")

        let barePayDescriptor = "addr(\(decodedAddress))"
        print("[SWAP] barePayDescriptor: \(barePayDescriptor)")

        if let checksum = try await lightningKit.getDescriptorInfo(descriptor: barePayDescriptor) {
            let payDescriptor = "\(barePayDescriptor)#\(checksum)"
            print("[SWAP] pay descriptor: \(payDescriptor)")
            self.payDescriptor = payDescriptor
        }
    }
    
    func commit() async throws {
        guard let swap = swap else { return }
        guard let descriptor = payDescriptor else { return }
        
        let scantx = try await lightningKit.scanTxOutSet(descriptor: descriptor)
        print(scantx)
        
        let success = scantx["success"] as! Int == 1 ? true : false

        if (!success) {
            print("[SWAP] scan for tx outputs failed")
            return
        }

        guard let currentHeight = scantx["height"] as? Int,
              let totalAmount = (scantx["total_amount"] as? NSNumber)?.decimalValue,
              let utxos = scantx["unspents"] as? [[String: Any]] else {
            return
        }
        
        let numUtxos = utxos.count
        let amountAndFee: Decimal = 0.0005
        
        if numUtxos == 0 {
            print("[SWAP] payment not received yet")
            // TODO: determine return contract
            return
        } else if numUtxos > 1 {
            print("[SWAP] multiple payments, numUtxos: \(numUtxos)")
            // TODO: determine return contract and implement handling in time
        } else if numUtxos == 1 {
            // current happy path
        } else {
            print("[SWAP] unusual value for numUtxos: \(numUtxos)")
        }
        
        let utxo = utxos.first!
        let paymentTxHeight = utxo["height"] as! Int
        let confirmations = currentHeight - paymentTxHeight + 1
        
        if (confirmations < REQUIRED_CONFIRMATIONS) {
            print("[SWAP] insufficient confirmations so far: \(confirmations) (must be 3 or greater)")
            return
        }
        
        let timeZero: Int32 = 12213123//swap.timelock - RELATIVE_SWAP_TIMELOCK
        let paymentDeadline = timeZero + RELATIVE_PAYMENT_DEADLINE
        
        if paymentTxHeight > paymentDeadline {
            print("[SWAP] L1 payment was made late, you really shouldn't have paid the invoice, payment height: \(paymentTxHeight), payment deadline: \(paymentDeadline), timelock: \(123312)")
        }

        if totalAmount < amountAndFee {
            print("[SWAP] amount paid insufficient, expect: \(amountAndFee), paid: \(totalAmount)")
            // TODO: determine return contract
            return
        }
        
//        let seekerInvoice = try lightningKit.decode(invoice: swapData.seekerInvoice)!
//
//        if swapData.hash != seekerInvoice.paymentHash()!.toHexString() {
//            print("[SWAP] Swap hash does not match payment hash for invoice")
//            return
//        }
        
//        let tx = try await lightningKit.pay(invoice: seekerInvoice)

//        print(tx)
        
        //TODO: Withdrawing tx create
    }
    
    func cancel() async throws {
        
    }
    
    private func scriptGenerator(secretSeekerPublicKey: String, secretHolderPublicKey: String, swapHash: String, timelock: Int32) -> [UInt8] {
        let secretSeekerPublicKeyData = Data(hex: secretSeekerPublicKey)
        let secretHolderPublicKeyData = Data(hex: secretHolderPublicKey)
        let swapHashData = Data(hex: swapHash)
        let hash160SwapHash = Crypto.ripeMd160(swapHashData)

        let timelockData = encodeScriptNumber(timelock)

        var scriptData = [UInt8]()
        scriptData.append(0xa9) // OP_HASH160
        scriptData.append(0x14) // Push 20 bytes (length of hash160)
        scriptData.append(contentsOf: hash160SwapHash)
        scriptData.append(0x87) // OP_EQUAL
        scriptData.append(0x63) // OP_IF
        scriptData.append(0x21) // OP_PUSHDATA(33) - since compressed public keys are 33 bytes long
        scriptData.append(contentsOf: secretSeekerPublicKeyData)
        scriptData.append(0x67) // OP_ELSE
        scriptData.append(contentsOf: timelockData) // Add the timelock value bytes
        scriptData.append(0xb1) // OP_CHECKLOCKTIMEVERIFY
        scriptData.append(0x75) // OP_DROP
        scriptData.append(0x21) // OP_PUSHDATA(33)
        scriptData.append(contentsOf: secretHolderPublicKeyData)
        scriptData.append(0x68) // OP_ENDIF
        scriptData.append(0xac) // OP_CHECKSIG

        return scriptData
    }
    
    private func encodeScriptNumber(_ num: Int32) -> [UInt8] {
        if num == 0 { return [] }
        
        var n = num
        var result = [UInt8]()
        
        while true {
            result.append(UInt8(n & 0xff))
            n >>= 8
            
            if (n == 0 && (result.last! & 0x80 == 0)) || (n == -1 && (result.last! & 0x80 != 0)) {
                break
            }
        }
        
        if result.last! & 0x80 != 0 {
            if num < 0 {
                result.append(0x80)
            } else {
                result.append(0x00)
            }
        }

        let lengthByte = UInt8(result.count) // Add the number of bytes used to encode the timelock value
        result.insert(lengthByte, at: 0)
        
        return result
    }

}
