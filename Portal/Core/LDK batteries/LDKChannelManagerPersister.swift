//
//  LDKChannelManagerPersister.swift
//  Portal
//
//  Created by farid on 6/13/22.
//

import Foundation
//import BitcoinCore
import LightningDevKit
import Combine

class LDKChannelManagerPersister: Persister, ExtendedChannelManagerPersister {
    private let dataService: ILightningDataService
    private let channelManager: ChannelManager
    
    init(channelManager: ChannelManager, dataService: ILightningDataService) {
        self.channelManager = channelManager
        self.dataService = dataService
        super.init()
    }
    
    func handleEvent(event: LightningDevKit.Event) {
        switch event.getValueType() {
        case .ChannelClosed:
            print("==============")
            print("CHANNEL CLOSED")
            print("==============")

            if let value = event.getValueAsChannelClosed() {
                let channelId = value.getUserChannelId()
//                dataService.removeChannelWith(id: channelId)
                
//                let id = value.getChannel_id().bytesToHexString()
//                let errorMessage: String
//                
//                let reason = value.getReason()
//                switch reason.getValueType() {
//                case .ProcessingError:
//                    let closingReasonMessage = "\(reason.getValueAsProcessingError()?.getErr() ?? "Unknown")"
//                    print("reason: \(closingReasonMessage)")
//                    errorMessage = "Channel \(id) closed: \(closingReasonMessage)"
//                case .CounterpartyForceClosed:
//                    let closingReasonMessage = "\(reason.getValueAsCounterpartyForceClosed()?.getPeer_msg() ?? "Unknown")"
//                    print("reason: \(closingReasonMessage)")
//                    errorMessage = "Channel \(id) closed: \(closingReasonMessage)"
//                case .none:
//                    errorMessage = "Channel \(id) closed: Unknown"
//                }
//
//                print(errorMessage)
            }
        case .DiscardFunding:
            print("================")
            print("DISCARD FUNDING")
            print("================")
            
            if let value = event.getValueAsDiscardFunding() {
                let channelId = value.getChannelId().toHexString()
                print("Channel id: \(channelId)")
                let errorMessage = "Channel \(channelId) closed: DISCARD FUNDING"
                print(errorMessage)
            }
        case .FundingGenerationReady:
            print("=========================")
            print("FUNDING GENERATION READY")
            print("=========================")
            
            if let fundingReadyEvent = event.getValueAsFundingGenerationReady() {
                let outputScript = fundingReadyEvent.getOutputScript()
                let amount = fundingReadyEvent.getChannelValueSatoshis()
                let channelId = fundingReadyEvent.getUserChannelId()

                do {
                    if let rawTx = try createRawTransaction(outputScript: outputScript, amount: amount) {
                        print("RAW TX: \(rawTx)")
                        let rawTxBytes = rawTx.bytes
                        let tcid = fundingReadyEvent.getTemporaryChannelId()

                        //TODO: fix counterparty_node_id
                        let sendingFundingTx = channelManager.fundingTransactionGenerated(
                            temporaryChannelId: tcid,
                            counterpartyNodeId: [],
                            fundingTransaction: rawTxBytes
                        )

                        if sendingFundingTx.isOk() {
                            print("funding tx sent")
                            let userMessage = "Chanel is open. Waiting funding tx to be confirmed"
                            print(userMessage)
                        } else if let errorDetails = sendingFundingTx.getError() {
                            print("sending failed")

//                            dataService.removeChannelWith(id: channelId)

                            let errorMessage: String

                            switch errorDetails.getValueType() {
                            case .ChannelUnavailable:
                                print("channel unavalibale")
                                let details = errorDetails.getValueAsChannelUnavailable()?.getErr()
                                errorMessage = "Cannot send funding transaction: Channel unavalibale \(String(describing: details))"
                            case .APIMisuseError:
                                print("APIMisuseError")
                                let details = errorDetails.getValueAsApiMisuseError()?.getErr()
                                errorMessage = "Cannot send funding transaction: Channel unavalibale \(String(describing: details))"
                            case .FeeRateTooHigh:
                                print("fee rate too hight")
                                errorMessage = "Cannot send funding transaction: Fee rate too hight"
                            case .InvalidRoute:
                                print("route error")
                                let details = errorDetails.getValueAsInvalidRoute()?.getErr()
                                errorMessage = "Cannot send funding transaction: Route error \(String(describing: details))"
                            case .MonitorUpdateInProgress:
                                print("Monitor update failed")
                                errorMessage = "Cannot send funding transaction: Monitor update failed"
                            case .IncompatibleShutdownScript:
                                print("IncompatibleShutdownScript")
                                let details = errorDetails.getValueAsIncompatibleShutdownScript()?.getScript()
                                errorMessage = "Cannot send funding transaction: Route error \(String(describing: details))"
                            @unknown default:
                                errorMessage = "Cannot send funding transaction: Unknown error"
                            }
                            
                            print(errorMessage)
                        }
                    }
                } catch {
                    print("Unable to create funding transactino error: \(error)")
//                    dataService.removeChannelWith(id: channelId)
                    
                    let errorMessage = "Unable to create funding transactino error: \(error)"
                    print(errorMessage)
                }
            }
//        case .PaymentReceived:
//            print("==================")
//            print("PAYMENT RECEIVED")
//            print("==================")
//
//            if let value = event.getValueAsPaymentReceived() {
//                let amount = value.getAmount_msat()/1000
//                print("Amount: \(amount)")
//                let paymentId = value.getPayment_hash().bytesToHexString()
//                print("Payment id: \(paymentId)")
//
//                let paymentPurpose = value.getPurpose()
//                let invoicePayment = paymentPurpose.getValueAsInvoicePayment()!
//                let preimage = invoicePayment.getPayment_preimage()
//                channelManager.claim_funds(payment_preimage: preimage)
//
//                let userMessage: String
//
//                print("Claimed")
//                let payment = LightningPayment(id: paymentId, satAmount: Int64(amount), created: Date(), description: "incoming payment", state: .received)
//                dataService.save(payment: payment)
//                userMessage = "Payment received: \(amount) sat"
//
//                print(userMessage)
//            }
        case .PaymentSent:
            print("==============")
            print("PAYMENT SENT")
            print("==============")
            
            if let value = event.getValueAsPaymentSent() {
                let paymentID = value.getPaymentId()
                let paymentHash = value.getPaymentHash()
            }
        case .PaymentPathFailed:
            print("====================")
            print("PAYMENT PATH FAILED")
            print("====================")
            
            let errorMessage: String
            
            if let value = event.getValueAsPaymentPathFailed() {
                print("Is rejected permanently: \(value.getPaymentFailedPermanently())")
                print("All paths failed: \(value.getAllPathsFailed())")
                errorMessage = "Payment path failed: permanently - \(value.getPaymentFailedPermanently()), all paths failed - \(value.getAllPathsFailed())"
            } else {
                errorMessage = "Payment path failed"
            }
            
            print(errorMessage)
                        
        case .PaymentFailed:
            print("================")
            print("PAYMENT FAILED")
            print("================")
            
            if let value = event.getValueAsPaymentFailed() {
                print("Payment id: \(value.getPaymentId().toHexString())")
            }
        case .PendingHTLCsForwardable:
            print("=========================")
            print("PendingHTLCsForwardable")
            print("=========================")
            
            channelManager.processPendingHtlcForwards()
        case .SpendableOutputs:
            print("=================")
            print("SpendableOutputs")
            print("=================")
        case .PaymentForwarded:
            print("=================")
            print("PaymentForwarded")
            print("=================")
        case .PaymentPathSuccessful:
            print("======================")
            print("PaymentPathSuccessful")
            print("======================")
        case .OpenChannelRequest:
            print("====================")
            print("OpenChannelRequest")
            print("====================")
        case .PaymentClaimable:
            print("====================")
            print("PaymentClaimable")
            print("====================")
        case .PaymentClaimed:
            print("====================")
            print("PaymentClaimed")
            print("====================")
        case .ProbeSuccessful:
            print("====================")
            print("ProbeSuccessful")
            print("====================")
        case .ProbeFailed:
            print("====================")
            print("ProbeFailed")
            print("====================")
        case .HTLCIntercepted:
            print("====================")
            print("HTLCIntercepted")
            print("====================")
        case .ChannelReady:
            print("====================")
            print("ChannelReady")
            print("====================")
        case .HTLCHandlingFailed:
            print("====================")
            print("HTLCHandlingFailed")
            print("====================")
        @unknown default:
            print("====================")
            print("Unknown")
            print("====================")
        }
    }
    
    
        
//    override func persist_manager(channel_manager: ChannelManager) -> Result_NoneErrorZ {
//        print("========================")
//        print("PERSIST CHANNEL MANAGER")
//        print("========================")
//
////        DispatchQueue.global(qos: .background).async {
//            let managerBytes = channel_manager.write()
//            self.dataService.save(channelManager: Data(managerBytes))
//
//            print("OUR NODE ID: \(channel_manager.getOurNodeId().toHexString())")
//            print("Avaliable channels: \(channel_manager.listChannels().count)")
//
//            for channel in channel_manager.listChannels() {
//                let userChannelID = channel.getUserChannelId()
//                let balance = channel.getBalanceMsat()/1000
//
//                print("CHANNEL ID: \(channel.getChannelId()?.toHexString() ?? "unknown")")
//                print("CHANNEL USER ID \(userChannelID)")
//                print("CHANNEL BALANCE: \(balance) sat")
//
//                if channel.getIsUsable() {
//                    print("CHANNEL IS USABLE")
//
//                    if let fetchedChannel = self.dataService.channelWith(id: userChannelID),
//                        fetchedChannel.state != .open ||
//                        fetchedChannel.satValue != balance
//                    {
//                        fetchedChannel.state = .open
//                        fetchedChannel.satValue = balance
//
//                        self.dataService.update(channel: fetchedChannel)
//                    }
//                } else {
//                    print("CHANNEL IS UNUSABLE")
//                    print("confirmation required: \(String(describing: channel.getConfirmationsRequired()))")
//
//                    if let fetchedChannel = self.dataService.channelWith(id: userChannelID),
//                        fetchedChannel.state != .waitingFunds ||
//                        fetchedChannel.satValue != balance
//                    {
//                        fetchedChannel.state = .waitingFunds
//                        fetchedChannel.satValue = balance
//
//                        self.dataService.update(channel: fetchedChannel)
//                    }
//                }
//            }
////        }
//
//        return Result_NoneErrorZ.ok()
//    }
    
//    override func persist_graph(network_graph: NetworkGraph) -> Result_NoneErrorZ {
//        print("PERSIST NET GRAPH")
//
//        let netGraphBytes = network_graph.write()
//        dataService.save(networkGraph: Data(netGraphBytes))
//
//        return Result_NoneErrorZ.ok()
//    }
    
    func createRawTransaction(outputScript: [UInt8], amount: UInt64) throws -> Data? {
        return nil
//        let scriptConverter = ScriptConverter()
//        let addressConverter = SegWitBech32AddressConverter(prefix: "tb", scriptConverter: scriptConverter)
//
//        let receiverAddress = try addressConverter.convert(keyHash: Data(outputScript), type: .p2wsh)
//        let address = receiverAddress.stringValue
//
//        guard let adapter = Portal.shared.adapterManager.adapter(for: .bitcoin()) as? BitcoinAdapter else { return nil }
//        return try adapter.createRawTransaction(amountSat: amount, address: address, feeRate: 80, sortMode: .shuffle)
    }
}
