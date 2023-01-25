//
//  LDKFeesEstimator.swift
//  Portal
//
//  Created by farid on 6/13/22.
//

import LightningDevKit

class LDKFeesEstimator: FeeEstimator {
    override func getEstSatPer_1000Weight(confirmationTarget: Bindings.ConfirmationTarget) -> UInt32 {
        return 253
    }
}

