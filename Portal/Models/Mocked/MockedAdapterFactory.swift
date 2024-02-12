//
//  MockedAdapterFactory.swift
//  Portal
//
//  Created by farid on 20.07.2023.
//

import Foundation

struct MockedAdapterFactory: IAdapterFactory {
    func adapter(wallet: Wallet) -> IAdapter? {
        MockedAdapter()
    }
}
