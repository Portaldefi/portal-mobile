//
//  IdentifiableString.swift
//  Portal
//
//  Created by farid on 10/20/22.
//

import Foundation

struct IdentifiableString: Identifiable {
    let id = UUID()
    let text: String
}
