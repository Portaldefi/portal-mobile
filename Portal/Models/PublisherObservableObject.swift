//
//  PublisherObservableObject.swift
//  Portal
//
//  Created by farid on 30.05.2023.
//

import Foundation
import Combine

final class PublisherObservableObject: ObservableObject {
    var subscriber: AnyCancellable?
    
    init(publisher: AnyPublisher<Void, Never>) {
        subscriber = publisher.sink(receiveValue: { [weak self] _ in
            self?.objectWillChange.send()
        })
    }
}
