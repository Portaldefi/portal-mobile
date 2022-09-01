//
//  BDKDemoAppApp.swift
//  BDKDemoApp
//
//  Created by farid on 7/20/22.
//

import SwiftUI

@main
struct BDKDemoAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
