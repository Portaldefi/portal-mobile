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

    override func broadcastTransaction(tx: [UInt8]) {
        print("Broadcasting Transaction")

        Task {
          try? await self.chainInterface.submitTransaction(transaction: tx)
        }
    }
}
