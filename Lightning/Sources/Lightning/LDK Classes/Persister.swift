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
        // do something to persist the graph
        let persistGraphResult = fileManager.persistGraph(graph: networkGraph.write())

        switch persistGraphResult {
        case .success():
            return Result_NoneErrorZ.initWithOk()
        case .failure(_):
            return Result_NoneErrorZ.initWithErr(e: .WriteZero)
        }
    }
    
    override func persistManager(channelManager: Bindings.ChannelManager) -> Bindings.Result_NoneErrorZ {
        let persistChannelManagerResult = fileManager.persistChannelManager(manager: channelManager.write())

        switch persistChannelManagerResult {
        case .success():
            return Result_NoneErrorZ.initWithOk()
        case .failure(_):
            return Result_NoneErrorZ.initWithErr(e: .WriteZero)
        }
    }
    
}
