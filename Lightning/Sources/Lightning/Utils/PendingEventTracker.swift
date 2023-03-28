//
//  File.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation
import LightningDevKit

actor PendingEventTracker {
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
    
    private func triggerContinuations(){
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
    
    func getCount() -> Int {
        return self.pendingManagerEvents.count
    }
    
    func getEvents() -> [Event] {
        return self.pendingManagerEvents
    }
    
    func getAndClearEvents() -> [Event]{
        let events = self.pendingManagerEvents
        self.pendingManagerEvents.removeAll()
        return events
    }
    
    func awaitAddition() async {
        await withCheckedContinuation({ continuation in
            self.continuations.append(continuation)
        })
    }
    
    func subscribe() -> AsyncStream<Event> {
        eventPublisher
    }
}
