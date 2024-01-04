//
//  IKeyboardReadable.swift
//  Portal
//
//  Created by farid on 20.12.2023.
//

import Foundation
import Combine
import SwiftUI

protocol IKeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> { get }
}

extension IKeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
}
