//
//  ChannelMonitor.swift
//  Portal
//
//  Created by farid on 2/2/23.
//

import Foundation

class ChannelMonitor: NSObject, NSCoding {
    let idBytes: [UInt8]
    let monitorBytes: [UInt8]
    
    init(idBytes: [UInt8], monitorBytes: [UInt8]) {
        self.idBytes = idBytes
        self.monitorBytes = monitorBytes
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(idBytes, forKey: "idBytes")
        coder.encode(monitorBytes, forKey: "monitorBytes")
    }
    
    required init?(coder: NSCoder) {
        idBytes = coder.decodeObject(forKey: "idBytes") as? [UInt8] ?? []
        monitorBytes = coder.decodeObject(forKey: "monitorBytes") as? [UInt8] ?? []
    }
}
