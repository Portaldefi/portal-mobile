//
//  NavigationStackView.swift
//  Portal
//
//  Created by farid on 12/1/22.
//

import SwiftUI
import Combine

enum Screen {
    typealias DismissAction = () -> (Void)
    typealias Identifier = String
    
    case account
    case send
    case receive
}

extension Screen {
    var id: Identifier {
        switch self {
        case .account:
            return "account_ID"
        case .send:
            return "send_ID"
        case .receive:
            return "receive_ID"
        }
    }
}

protocol NavigationConfigurator {
    var defaultAnimation: Animation { get }
    func configure(_ screen: Screen) -> ViewElement?
}

extension NavigationConfigurator {
    var defaultAnimation: Animation { Animation.easeInOut(duration: 0.2) }
}

struct NavigationStackView<Root>: View where Root: View {
    @ObservedObject private var navigationStack: NavigationStack
    
    private let rootViewID = "Root"
    private let rootView: Root
    private let defaultTransitions = NavigationTransition.defaultTransitions
    private let rootViewtransitions: (push: AnyTransition, pop: AnyTransition)
    
    init(
        transitionType: NavigationTransition = .default,
        configurator: NavigationConfigurator,
        rootView: Root
    ) {
        self.rootView = rootView
        self.navigationStack = NavigationStack(configurator: configurator)
        
        switch transitionType {
        case .none:
            self.rootViewtransitions = (.identity, .identity)
        case .custom(let transition):
            self.rootViewtransitions = (transition, transition)
        default:
            self.rootViewtransitions = defaultTransitions
        }
    }
    
    public var body: some View {
        VStack {
            let navigationType = navigationStack.navigationType

            if let currentView = navigationStack.currentView {
                let popTransition = currentView.popTransition
                let pushTransition = currentView.pushTransition
                
                currentView.wrappedElement
                    .id(currentView.id)
                    .transition(navigationType == .push ? pushTransition : popTransition)
            } else {
                rootView
                    .id(rootViewID)
                    .transition(navigationType == .push ? rootViewtransitions.push : rootViewtransitions.pop)
            }
        }
        .environmentObject(navigationStack)
    }
}

