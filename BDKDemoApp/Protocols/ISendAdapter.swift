//
//  ISendAdapter.swift
//  BDKDemoApp
//
//  Created by farid on 10/4/22.
//

import Foundation

protocol ISendAdapter {
    func send(to: String, amount: String, completion: @escaping (Error?) -> Void)
}
