//
//  OpenChannelViewModel.swift
//  Portal
//
//  Created by farid on 20.12.2023.
//

import Foundation
import Factory

@Observable class OpenChannelViewModel {
    @ObservationIgnored private var manager: ILightningKitManager
    @ObservationIgnored var peers: [Peer]
    
    init(manager: ILightningKitManager) {
        self.manager = manager
        let config = Container.configProvider()
        
        switch config.network {
        case .playnet:
            peers = [.alice, .bob]
        case .testnet, .mainnet:
            peers = [.mlCom, .aranguren, .openNode]

        }
    }
    
    func connect(_ peer: Peer, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                try await manager.connectPeer(peer)
                completion(true)
            } catch {
                print("Connection Error: \(error)")
                completion(false)
            }
        }
    }
}

extension OpenChannelViewModel {
    static func config() -> OpenChannelViewModel {
        OpenChannelViewModel(manager: Container.lightningKitManager())
    }
}
