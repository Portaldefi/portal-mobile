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
    let lightningKit: ILightningKitManager
    let persistenceController: PersistenceController
    
    init() {
        lightningKit = Container.lightningKitManager()
        persistenceController = PersistenceController.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    Task {
                        try await lightningKit.start()
                    }
                }
        }
    }
}
