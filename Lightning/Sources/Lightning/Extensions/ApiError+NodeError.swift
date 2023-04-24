//
//  File.swift
//  
//
//  Created by Jurvis on 12/15/22.
//

import Foundation
import LightningDevKit

extension APIError {
    func getLDKError() -> NodeError.Channels {
        if let _ = self.getValueAsApiMisuseError() {
            return .apiMisuse
        } else if let _ = self.getValueAsInvalidRoute() {
            return .router
        } else if let _ = self.getValueAsChannelUnavailable() {
            return .channelUnavailable
        } else if let _ = self.getValueAsFeeRateTooHigh() {
            return .feeRatesTooHigh
        } else if let _ = self.getValueAsIncompatibleShutdownScript() {
            return .incompatibleShutdownScript
        }
        
        return .unknown
    }
}
