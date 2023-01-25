//
//  ILightningSerivice.swift
//  Portal
//
//  Created by farid on 5/16/22.
//  Copyright © 2022 Tides Network. All rights reserved.
//

import Foundation
import Combine

protocol ILightningService {
    var blockChainDataSynced: CurrentValueSubject<Bool, Never> { get }

    var dataService: ILightningDataService { get }
    var manager: ILightningChannelManager { get }
    
    func connect(node: LightningNode) -> Bool
    func disconnect(node: LightningNode)
    func openChannelWith(node: LightningNode, sat: Int64)
    func createInvoice(amount: String, memo: String) -> String?
    func pay(invoice: String) throws
    func syncBlockchainData() async throws
}
