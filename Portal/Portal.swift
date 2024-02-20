//
//  Portal.swift
//  Portal
//
//  Created by farid on 7/20/22.
//

import SwiftUI
import Bugsnag
import BugsnagPerformance
import Mixpanel

@main
struct Portal: App {
    @UIApplicationDelegateAdaptor(NotificationDelegate.self) var delegate
    let persistenceController: PersistenceController
    
    init() {
        persistenceController = PersistenceController.shared
        
        Bugsnag.start()
        BugsnagPerformance.start()
        
        Mixpanel.initialize(token: "80cf661b81aa75a2b0a6edabb3c3705d", trackAutomaticEvents: true)
        Mixpanel.mainInstance().track(event: "Start Portal")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
