//
//  SwapTransactionRecord.swift
//  Portal
//
//  Created by farid on 12.01.2024.
//

import Foundation
import PortalSwapSDK

class SwapTransactionRecord: TransactionRecord {
    private let satsInBtc: Decimal = 100_000_000
    private let weiInEth: Decimal = 1_000_000_000_000_000_000
    
    let base: Coin
    let quote: Coin
    
    let baseQuantity: Decimal
    let quoteQuantity: Decimal
    
    let party: PartyModel
    let partyType: PartyType
    
    init(swap: SwapModel, userData: TxUserData) {
        switch swap.partyType {
        case .secretHolder:
            party = swap.secretHolder
            baseQuantity = Decimal(swap.secretHolder.quantity) / satsInBtc
            quoteQuantity = Decimal(swap.secretSeeker.quantity) / weiInEth
            base = .lightningBitcoin()
            quote = .ethereum()
        case .secretSeeker:
            party = swap.secretSeeker
            baseQuantity = Decimal(swap.secretSeeker.quantity) / weiInEth
            quoteQuantity = Decimal(swap.secretHolder.quantity) / satsInBtc
            base = .ethereum()
            quote = .lightningBitcoin()
        }
        
        partyType = swap.partyType
        
        let type: TxType = .swap(base: base, quote: quote)
        let source: TxSource = .swap(base: base, quote: quote)
        
        super.init(source: source, type: type, id: swap.swapId, timestamp: Int(swap.timestamp), userData: userData)
    }
}
