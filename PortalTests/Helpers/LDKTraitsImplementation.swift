//
//  LDKTraitsImplementation.swift
//  PortalTests
//
//  Created by farid on 22.11.2023.
//

import Foundation
import LightningDevKit
import Combine

class LDKTraitImplementations {

    class PlaynetFeeEstimator: FeeEstimator {
        override func getEstSatPer1000Weight(confirmationTarget: Bindings.ConfirmationTarget) -> UInt32 {
            return 253
        }
    }

    class PlaynetBroadcaster: BroadcasterInterface {

        private let rpcInterface: BlockchainObserver

        init(rpcInterface: BlockchainObserver) {
            self.rpcInterface = rpcInterface
            super.init()
        }

        override func broadcastTransactions(txs: [[UInt8]]) {
            Task {
                for tx in txs {
                    do {
                        let txId = try await self.rpcInterface.submitTransaction(transaction: tx)
                        print("broadcasted tx with id: \(txId)")
                    } catch {
//                        print("failed to broadcast tx: \(tx), error: \(error)")
                    }
                }
            }
        }
    }
    
    class MuteBroadcaster: BroadcasterInterface {
        override func broadcastTransactions(txs: [[UInt8]]) {
            // do nothing
        }
    }

    class PlaynetLogger: Logger {
        let logLevels: [Bindings.Level]
        let id: String
        
        init(id: String, logLevels: [Bindings.Level]) {
            self.id = id
            self.logLevels = logLevels
        }
        
        override func log(record: Bindings.Record) {
            let messageLevel = record.getLevel()
            let arguments = record.getArgs()
                    
            guard logLevels.contains(messageLevel) else { return }
            
            switch messageLevel {
            case .Debug:
                print("\(id) LDK LOG - Debug:")
                print("\(arguments)\n")
            case .Info:
                print("\(id) LDK LOG - Info:")
                print("\(arguments)\n")
            case .Warn:
                print("\(id) LDK LOG - Warn:")
                print("\(arguments)\n")
            case .Error:
                print("\(id) LDK LOG - Error:")
                print("\(arguments)\n")
            case .Gossip:
                break //print("\nGossip Logger:\n>\(arguments)\n")
            case .Trace:
                print("\(id) LDK LOG - Trace:")
                print("\(arguments)\n")
            default:
                print("\(id) LDK LOG - Unknown:")
                print("\(arguments)\n")
            }
        }
    }
    
    class MuteLogger: Logger {
        override func log(record: Bindings.Record) {
            // do nothing
        }
    }

    class PlaynetChannelMonitorPersister: Persist {
        override func persistNewChannel(channelId: OutPoint, data: ChannelMonitor, updateId: MonitorUpdateId) -> Bindings.ChannelMonitorUpdateStatus {
            let _: [UInt8] = channelId.write()
            let _: [UInt8] = data.write()
            return .Completed
        }

        override func updatePersistedChannel(channelId: OutPoint, update: ChannelMonitorUpdate, data: ChannelMonitor, updateId updateIId: MonitorUpdateId) -> Bindings.ChannelMonitorUpdateStatus {
            let _: [UInt8] = channelId.write()
            let _: [UInt8] = data.write()
            return .Completed
        }
    }

    class PlaynetChannelManagerAndNetworkGraphPersisterAndEventHandler: Persister, ExtendedChannelManagerPersister {
        let eventTracker = PendingEventTracker()
        let onNodeEventUpdate = PassthroughSubject<Event, Never>()
        let id: String
        
        init(id: String) {
            self.id = id
            super.init()
        }
        
        func getManagerEvents(expectedCount: UInt) async -> [Event] {
            while true {
                if await self.eventTracker.getCount() >= expectedCount {
                    return await self.eventTracker.getAndClearEvents()
                }
                await self.eventTracker.awaitAddition()
            }
        }
        
        func handleEvent(event: Event) {
            Task {
                await self.eventTracker.addEvent(event: event)
                onNodeEventUpdate.send(event)
            }
        }
        
        override func persistManager(channelManager: Bindings.ChannelManager) -> Bindings.Result_NoneIOErrorZ {
            Result_NoneIOErrorZ.initWithOk()
        }
        
        override func persistGraph(networkGraph: Bindings.NetworkGraph) -> Bindings.Result_NoneIOErrorZ {
            Result_NoneIOErrorZ.initWithOk()
        }
        
        override func persistScorer(scorer: LightningDevKit.Bindings.WriteableScore) -> LightningDevKit.Bindings.Result_NoneIOErrorZ {
            Result_NoneIOErrorZ.initWithOk()
        }
        
        
        actor PendingEventTracker {
            enum NodeEvent {
                case paymentClaimable
                case paymentClaimed
                case paymentSent
                case paymentFailed
                case paymentPathSuccessful
                case paymentPathFailed
                case probeSuccessful
                case probeFailed
                case pendingHTLCsForwardable
                case spendableOutputs
                case paymentForwarded
                case channelClosed
                case discardFunding
                case openChannelRequest
                case htlcHandlingFailed
                case fundingGenerationReady
            }
            var isObserving: Bool = false
            private(set) var pendingManagerEvents: [Event] = []
            private(set) var continuations: [CheckedContinuation<Void, Never>] = []
            private(set) var eventContinuations: [AsyncStream<Event>.Continuation] = []
            //Async publisher will emit events stream down to subscribers
            private lazy var eventPublisher: AsyncStream<Event> = {
                AsyncStream(Event.self) { [unowned self] continuation in
                    self.addEventContinuation(continuation)
                }
            }()
            
            private func addEventContinuation(_ continuation: AsyncStream<Event>.Continuation) {
                self.eventContinuations.append(continuation)
            }
            
            private func triggerContinuations() {
                let continuations = self.continuations
                self.continuations.removeAll()
                for currentContinuation in continuations {
                    currentContinuation.resume()
                }
            }
            
            func addEvent(event: Event) {
                self.pendingManagerEvents.append(event)
                self.triggerContinuations()
                for continuation in eventContinuations {
                    continuation.yield(event)
                }
            }
            
            func addEvents(events: [Event]) {
                self.pendingManagerEvents.append(contentsOf: events)
                self.triggerContinuations()
                for event in events {
                    for continuation in eventContinuations {
                        continuation.yield(event)
                    }
                }
            }
            
            private func getEventAndClear() -> Event {
                let event = self.pendingManagerEvents[0]
                self.pendingManagerEvents.removeAll()
                isObserving = false
                return event
            }
            
            func getCount() -> Int {
                return self.pendingManagerEvents.count
            }
            
            func getEvents() -> [Event] {
                return self.pendingManagerEvents
            }
            
            func getAndClearEvents() -> [Event] {
                let events = self.pendingManagerEvents
                self.pendingManagerEvents.removeAll()
                return events
            }
            
            private func waitForNextEvent() {
                pendingManagerEvents.removeAll()
            }
            
            func awaitAddition() async {
                isObserving = true
                await withCheckedContinuation({ continuation in
                    continuations.append(continuation)
                })
            }
            
            func await(events: [NodeEvent], timeout: TimeInterval) async -> Event? {
                let timeoutDate = Date(timeIntervalSinceNow: timeout)
                
                while timeoutDate >= Date() {
                    if !pendingManagerEvents.isEmpty {
                        let event = pendingManagerEvents[0]
                        let eventType: PendingEventTracker.NodeEvent?
                        
                        if event.getValueAsPaymentPathSuccessful() != nil { eventType = .paymentPathSuccessful }
                        else if event.getValueAsPaymentPathFailed() != nil { eventType = .paymentPathFailed }
                        else if event.getValueAsPaymentFailed() != nil { eventType = .paymentFailed }
                        else if event.getValueAsPaymentClaimed() != nil { eventType = .paymentClaimed }
                        else if event.getValueAsPaymentClaimable() != nil { eventType = .paymentClaimable }
                        else if event.getValueAsPaymentSent() != nil { eventType = .paymentSent }
                        else if event.getValueAsProbeSuccessful() != nil { eventType = .probeSuccessful }
                        else if event.getValueAsProbeFailed() != nil { eventType = .probeFailed }
                        else if event.getValueAsPendingHtlcsForwardable() != nil { eventType = .pendingHTLCsForwardable }
                        else if event.getValueAsHtlcHandlingFailed() != nil { eventType = .htlcHandlingFailed }
                        else if event.getValueAsSpendableOutputs() != nil { eventType = .spendableOutputs }
                        else if event.getValueAsPaymentForwarded() != nil { eventType = .paymentForwarded }
                        else if event.getValueAsChannelClosed() != nil { eventType = .channelClosed }
                        else if event.getValueAsDiscardFunding() != nil { eventType = .discardFunding }
                        else if event.getValueAsOpenChannelRequest() != nil { eventType = .openChannelRequest }
                        else if event.getValueAsFundingGenerationReady() != nil { eventType = .fundingGenerationReady }
                        else { eventType = nil }
                        
                        if let eventType = eventType, events.contains(eventType) {
                            return getEventAndClear()
                        } else {
                            waitForNextEvent()
                        }
                    }
                    await awaitAddition()
                }
                // in case of timeout
                print("Timeout ")
                return nil
            }
            
            func subscribe() -> AsyncStream<Event> {
                eventPublisher
            }
        }
    }
    
    struct Listener: BlockchainListener {
        private let channelManager: ChannelManager
        private let chainMonitor: ChainMonitor

        init(channelManager: ChannelManager, chainMonitor: ChainMonitor) {
            self.channelManager = channelManager
            self.chainMonitor = chainMonitor
        }

        func blockConnected(block: [UInt8], height: UInt32) {
            self.channelManager.asListen().blockConnected(block: block, height: height)
            self.chainMonitor.asListen().blockConnected(block: block, height: height)
        }

        func blockDisconnected(header: [UInt8]?, height: UInt32) {
            self.chainMonitor.asListen().blockDisconnected(header: header, height: height)
            self.channelManager.asListen().blockDisconnected(header: header, height: height)
        }
    }

}
