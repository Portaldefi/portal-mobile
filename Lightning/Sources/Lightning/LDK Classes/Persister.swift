//
//  File.swift
//  
//
//  Created by Jurvis on 9/4/22.
//

import Foundation
import LightningDevKit

class Persister: LightningDevKit.Persister, ExtendedChannelManagerPersister {
    let fileManager = LightningFileManager()
    weak var tracker: PendingEventTracker?
    
    init(eventTracker: PendingEventTracker? = nil) {
        self.tracker = eventTracker
        super.init()
    }

    func handleEvent(event: LightningDevKit.Event) {
        guard let tracker = tracker else { return }
        
        Task {
            await tracker.addEvent(event: event)
        }
    }
        
    override func persistGraph(networkGraph: Bindings.NetworkGraph) -> Bindings.Result_NoneErrorZ {
        print("[PERSISTER] Persisting net graph")
        // do something to persist the graph
        let persistGraphResult = fileManager.persistGraph(graph: networkGraph.write())

        switch persistGraphResult {
        case .success():
            return Result_NoneErrorZ.initWithOk()
        case .failure(_):
            print("[PERSISTER] Persisting net graph FAILURE")
            return Result_NoneErrorZ.initWithErr(e: .WriteZero)
        }
    }
    
    override func persistManager(channelManager: Bindings.ChannelManager) -> Bindings.Result_NoneErrorZ {
        print("[PERSISTER] Persisting channel manager")
        let persistChannelManagerResult = fileManager.persistChannelManager(manager: channelManager.write())

        switch persistChannelManagerResult {
        case .success():
            return Result_NoneErrorZ.initWithOk()
        case .failure(_):
            print("[PERSISTER] Persisting channel manager FAILURE")
            return Result_NoneErrorZ.initWithErr(e: .WriteZero)
        }
    }
    
    override func persistScorer(scorer: LightningDevKit.Bindings.WriteableScore) -> LightningDevKit.Bindings.Result_NoneErrorZ {
        print("[PERSISTER] Persisting scorer")

        let persistScorerResult = fileManager.persistScorer(scorer: scorer.write())

        switch persistScorerResult {
        case .success():
            return Result_NoneErrorZ.initWithOk()
        case .failure(_):
            print("[PERSISTER] Persisting scorer FAILURE")
            return Result_NoneErrorZ.initWithErr(e: .WriteZero)
        }
    }
    
}
