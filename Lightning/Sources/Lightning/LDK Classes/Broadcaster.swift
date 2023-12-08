//
//  Broadcaster.swift
//  Conforms to the `BroadcasterInterface` protocol, which establishes behavior for broadcasting
//  a transaction to the Bitcoin network.
//
//  Created by Jurvis on 9/5/22.
//

import Foundation
import LightningDevKit

class Broadcaster: BroadcasterInterface {
    private let chainInterface: RpcChainManager
    
    init(rpcInterface: RpcChainManager) {
        self.chainInterface = rpcInterface
        super.init()
    }
    
    override func broadcastTransactions(txs: [[UInt8]]) {
        Task {
            for tx in txs {
                if
                    let json = try? await chainInterface.decodeRawTransaction(tx: tx),
                    let result = json["result"] as? [String: Any],
                    let txId = result["txid"] as? String  {
                    print(txId)
                    
                    //                if let transaction = try? await chainInterface.getTransaction(with: txId) {
                    //                    print("transaction: \(transaction.toHexString())")
                    //                } else {
                    let txID = try? await self.chainInterface.submitTransaction(transaction: tx)
                    print("Submitted tx with id: \(String(describing: txID))")
                    //                }
                } else {
                    let txID = try? await self.chainInterface.submitTransaction(transaction: tx)
                    print("Submitted tx with id: \(String(describing: txID))")
                }
            }
        }
    }
}
