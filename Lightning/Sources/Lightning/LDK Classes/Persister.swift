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

    func handle_event(event: LightningDevKit.Event) {
        guard let tracker = tracker else { return }
        
        Task {
            await tracker.addEvent(event: event)
        }
    }
    
    override func persist_graph(network_graph: NetworkGraph) -> Result_NoneErrorZ {
        let persistGraphResult = fileManager.persistGraph(graph: network_graph.write())

        switch persistGraphResult {
        case .success():
            return Result_NoneErrorZ.ok()
        case .failure(_):
            return Result_NoneErrorZ.err(e: LDKIOError_WriteZero)
        }
    }
    
    override func persist_manager(channel_manager: ChannelManager) -> Result_NoneErrorZ {
        let persistChannelManagerResult = fileManager.persistChannelManager(manager: channel_manager.write())

        switch persistChannelManagerResult {
        case .success():
            return Result_NoneErrorZ.ok()
        case .failure(_):
            return Result_NoneErrorZ.err(e: LDKIOError_WriteZero)
        }
    }
    
    override func persist_scorer(scorer: LightningDevKit.Bindings.MultiThreadedLockableScore) -> LightningDevKit.Bindings.Result_NoneErrorZ {
        Result_NoneErrorZ.ok()
    }
    
}
