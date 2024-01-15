//
//  SwapTransactionRecord.swift
//  Portal
//
//  Created by farid on 12.01.2024.
//

import Foundation
import PortalSwapSDK

class SwapTransactionRecord: TransactionRecord {
    let base: Coin
    let quote: Coin
    
    let baseQuantity: Decimal
    let quoteQuantity: Decimal
    
    init(swap: DBSwap, userData: TxUserData) {
        switch swap.partyType {
        case "holder":
            baseQuantity = Decimal(swap.secretHolder?.quantity ?? 0) / 100_000_000
            quoteQuantity = Decimal(swap.secretSeeker?.quantity ?? 0) / 1_000_000_000_000_000_000
            base = .lightningBitcoin()
            quote = .ethereum()
        case "seeker":
            baseQuantity = Decimal(swap.secretSeeker?.quantity ?? 0) / 1_000_000_000_000_000_000
            quoteQuantity = Decimal(swap.secretHolder?.quantity ?? 0) / 100_000_000
            base = .ethereum()
            quote = .lightningBitcoin()
        default:
            fatalError("Unknown partyType")
        }
        
        let type: TxType = .swap(base: base, quote: quote)
        let source: TxSource = .swap(base: base, quote: quote)
        
        super.init(source: source, type: type, id: swap.swapID!, timestamp: Int(swap.timestamp), userData: userData)
    }
}
