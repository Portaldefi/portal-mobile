//
//  IAdapter.swift
//  Portal
//
//  Created by Farid on 13.07.2021.
//

import Foundation

protocol IAdapter: AnyObject {
    func start()
    func stop()
    func refresh()
    var debugInfo: String { get }
}
