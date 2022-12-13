//
//  NavigationStack.swift
//  Portal
//
//  Created by farid on 12/1/22.
//

import Combine
import SwiftUI

enum NavigationTransition {
    case none
    case `default`
    case custom(AnyTransition)
    
    static var defaultTransitions: (push: AnyTransition, pop: AnyTransition) {
        let pushTransition = AnyTransition.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
        let popTransition = AnyTransition.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
        return (pushTransition, popTransition)
    }
}

enum NavigationType {
    case push
    case pop
}

class NavigationStack: ObservableObject {
    private let configurator: NavigationConfigurator
    
    @Published private(set) var navigationType = NavigationType.push
    @Published private(set) var currentView: ViewElement?
    
    init(configurator: NavigationConfigurator) {
        self.configurator = configurator
    }
    
    private var viewStack = ViewStack() {
        didSet {
            currentView = viewStack.peek()
        }
    }
    
    func push(_ screen: Screen) {
        if let element = configurator.configure(screen) {
            navigationType = .push
            
            withAnimation(.easeInOut(duration: 0.3)) {
                viewStack.push(element)
            }
        }
    }
    
    func pop(to screen: Screen? = nil) {
        navigationType = .pop
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if let view = screen {
                viewStack.popToView(withId: view.id)
            } else {
                viewStack.popToPrevious()
            }
        }
    }
    
    func popToRoot() {
        viewStack.popToRoot()
    }
    
    
    private struct ViewStack {
        private var views = [ViewElement]()
        
        func peek() -> ViewElement? {
            views.last
        }
        
        mutating func push(_ element: ViewElement) {
            if indexForView(withId: element.id) != nil {
                self.popToView(withId: element.id)
            }
            views.append(element)
        }
        
        mutating func popToPrevious() {
            _ = views.popLast()
        }
        
        mutating func popToView(withId identifier: Screen.Identifier) {
            guard let viewIndex = indexForView(withId: identifier) else {
                fatalError("Identifier \"\(identifier)\" not found. Can not pop a view that doesn't exist.")
            }
            views.removeLast(views.count - (viewIndex + 1))
        }
        
        mutating func popToRoot() {
            views.removeAll()
        }
        
        private func indexForView(withId identifier: Screen.Identifier) -> Int? {
            views.firstIndex {
                $0.id == identifier
            }
        }
    }
}

struct ViewElement: Identifiable, Equatable {
    let id: Screen.Identifier
    let wrappedElement: AnyView
    let pushTransition: AnyTransition
    let popTransition: AnyTransition
    
    init(id: Screen.Identifier, wrappedElement: AnyView, pushTransition: AnyTransition? = nil, popTransition: AnyTransition? = nil) {
        self.id = id
        self.wrappedElement = wrappedElement
        
        if let push = pushTransition {
            self.pushTransition = push
        } else {
            self.pushTransition = NavigationTransition.defaultTransitions.push
        }
        if let pop = popTransition {
            self.popTransition = pop
        } else {
            self.popTransition = NavigationTransition.defaultTransitions.pop
        }
    }
    
    static func == (lhs: ViewElement, rhs: ViewElement) -> Bool {
        lhs.id == rhs.id
    }
}

