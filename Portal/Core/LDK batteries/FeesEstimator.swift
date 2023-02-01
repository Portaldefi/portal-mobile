//
//  FeesEstimator.swift
//  Portal
//
//  Created by farid on 6/13/22.
//

import LightningDevKit

class FeesEstimator: LightningDevKit.FeeEstimator {
    override func getEstSatPer_1000Weight(confirmationTarget: Bindings.ConfirmationTarget) -> UInt32 {
        // This number is the feerate to work with LND nodes in testnet
        // (https://github.com/lightningnetwork/lnd/blob/master/chainreg/chainregistry.go#L140-L142)
        return 1250
    }
}

