//
//  File.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation
import LightningDevKit

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
        return event
    }
    
    private func waitForNextEvent() {
        pendingManagerEvents.removeAll()
    }
    
    private func awaitAddition() async {
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


