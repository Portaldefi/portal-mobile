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
        if let value = self.getValueAsApiMisuseError() {
            return .apiMisuse(value.getErr())
        } else if let value = self.getValueAsInvalidRoute() {
            return .router(value.getErr())
        } else if let value = self.getValueAsChannelUnavailable() {
            return .channelUnavailable(value.getErr())
        } else if let value = self.getValueAsFeeRateTooHigh() {
            return .feeRatesTooHigh(value.getErr())
        } else if let _ = self.getValueAsIncompatibleShutdownScript() {
            return .incompatibleShutdownScript
        }
        
        return .unknown
    }
}
