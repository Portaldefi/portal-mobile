//
//  BitcoinDevKitTransaction+Extension.swift
//  BDKDemoApp
//
//  Created by farid on 10/3/22.
//

import BitcoinDevKit

extension BitcoinDevKit.Transaction {
    static var mockedConfirmed: BitcoinDevKit.Transaction {
        let details = TransactionDetails(
            fee: 141,
            received: 55000,
            sent: 0,
            txid: "088719f8db335b69c1e1a57b06d6925c941e99bf55607394e0902283a70fd44e"
        )
        let blockTime = BlockTime(height: 2345912, timestamp: 1662707961)
        
        return BitcoinDevKit.Transaction.confirmed(details: details, confirmation: blockTime)
    }
}
