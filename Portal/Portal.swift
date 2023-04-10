//
//  Portal.swift
//  Portal
//
//  Created by farid on 7/20/22.
//

import SwiftUI
import Factory

@main
struct Portal: App {
    let persistenceController: PersistenceController
    
    init() {
        persistenceController = PersistenceController.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
