//
//  Portal.swift
//  Portal
//
//  Created by farid on 7/20/22.
//

import SwiftUI

@main
struct Portal: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
