//
//  TxLabel.swift
//  Portal
//
//  Created by farid on 10/3/22.
//

import Foundation

struct TxLabel: Identifiable, Hashable {
    let id: UUID = UUID()
    var label: String
}
