//
//  TestFlowExeprions.swift
//  PortalTests
//
//  Created by farid on 22.11.2023.
//

import Foundation
import LightningDevKit

enum TestFlowExceptions: Error {
    case unexpectedChannelManagerEventType
    case missingInvoicePayer
    case invoiceParsingError(ParseOrSemanticError)
    case hexParsingError
    case invalidOutputScript
    case outputScriptMissingAddresses
    case paymentPathUnsuccessful
    case fundingTxError
    case failedToConnectToAlice
    case gotChannelCloseEvent(String)
}
