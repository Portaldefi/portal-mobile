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
        if let _ = self.getValueAsAPIMisuseError() {
            return .misuse
        } else if let _ = self.getValueAsRouteError() {
            return .value
        } else if let error = self.getValueAsChannelUnavailable() {
            print(error.getErr())
            return .unavailable
        } else if let _ = self.getValueAsFeeRateTooHigh() {
            return .feeTooHigh
        } else if let _ = self.getValueAsIncompatibleShutdownScript() {
            return .incompatibleShutdown
        }
        
        return .unknown
    }
}
