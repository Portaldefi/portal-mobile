//
//  LightningNode.swift
//  Portal
//
//  Created by farid on 6/6/22.
//

import Foundation

class LightningNode: Identifiable {
    var id: String {
        publicKey
    }
    let alias: String
    let publicKey: String
    let host: String
    let port: UInt16
    var channels: [LightningChannel]
    var connected: Bool
    var nodeId: [UInt8] {
        publicKey.hexStringToBytes() ?? []
    }
    
    init(alias: String, publicKey: String, host: String, port: UInt16) {
        self.alias = alias
        self.publicKey = publicKey
        self.host = host
        self.port = port
        self.channels = [LightningChannel]()
        self.connected = false
    }
    
//    init(record: DBLightningNode) {
//        self.alias = record.alias
//        self.publicKey = record.publicKey
//        self.host = record.host
//        self.port = UInt16(record.port)
//        let dbChannels = record.channels.sortedArray(using: []) as? [DBLightningChannel]
//        self.channels = dbChannels?.map{ LightningChannel(record: $0) } ?? [LightningChannel]()
//        self.connected = false
//    }
    
    static var sampleNodes: [LightningNode] {
        [LightningNode(
            alias: "aranguren.org",
            publicKey: "038863cf8ab91046230f561cd5b386cbff8309fa02e3f0c3ed161a3aeb64a643b9",
            host: "203.132.94.196",
            port: 9735
        ),
        LightningNode(
            alias: "ali/sand/pre",
            publicKey: "02202007c9fded3b8c042cc1c2583abd3c248f0f6d596eb899a6096bf537a0ede2",
            host: "35.224.10.41",
            port: 9735
        ),
        LightningNode(
            alias: "OGLE-TR-122",
            publicKey: "030bac1d62b6838a57c301d7e0244729b9699a8dacffcfbde359abc2cc20701a3a",
            host: "5.196.73.52",
            port: 9737
        ),
        LightningNode(
            alias: "SANDBOX_LN_Oracle_Network",
            publicKey: "02013e9b82ba5076e5abf67971e13a4d6a13c1aad18e8bdb3a431c4d137246c101",
            host: "217.173.236.67",
            port: 29735
        ),
        LightningNode(
            alias: "Node: 173.249.2.64",
            publicKey: "0248524e89ac0bb0770451f8a20b3f2b279639ea12c84dec8c581d7b9cd9e855f7",
            host: "173.249.2.64",
            port: 31696
        )]
    }
}
