//
//  ISendAdapter.swift
//  Portal
//
//  Created by farid on 10/4/22.
//

import Foundation

protocol ISendAdapter {
    func sendMax(to: String, fee: Int?, completion: @escaping (String?, Error?) -> Void)
    func send(to: String, amount: String, fee: Int?, completion: @escaping (String?, Error?) -> Void)
}
