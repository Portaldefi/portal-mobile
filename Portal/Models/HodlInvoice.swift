import Foundation
import PortalSwapSDK

public class HodlInvoice {
    public let id: String
    public let description: String
    public let tokens: UInt64
    public let paymentRequest: String
    
    public var subscription: InvoiceSubscription
        
    public init(id: String, description: String, tokens: UInt64, paymentRequest: String) {
        self.id = id
        self.description = description
        self.tokens = tokens
        self.paymentRequest = paymentRequest
        self.subscription = InvoiceSubscription()
    }
    
    public func update(status: InvoiceSubscription.Status) {
        subscription.update(status: status)
    }
}
