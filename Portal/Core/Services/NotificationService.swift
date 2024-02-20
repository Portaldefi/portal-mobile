//
//  NotificationService.swift
//  Portal
//
//  Created by Farid on 28.06.2021.
//

import Foundation
import AVFoundation
import Combine
import UserNotifications

final class NotificationService: INotificationService {
    private let player: AVPlayer?
    
    private(set) var notifications = CurrentValueSubject<[PNotification], Never>([])
    private(set) var newAlerts = CurrentValueSubject<Int, Never>(0)
    private(set) var alertsBeenSeen = CurrentValueSubject<Bool, Never>(false)
    
    private var accountId: String?
    private let settings: IPortalSettings
    private var subscriptions = Set<AnyCancellable>()
        
    init(accountManager: IAccountManager, settings: IPortalSettings) {
//        if let url = Bundle.main.url(forResource: "alert", withExtension: "mp3") {
//            player = AVPlayer.init(url: url)
//        } else {
            player = nil
//        }
        self.settings = settings
        
        accountId = accountManager.activeAccount?.id
        
        accountManager
            .onActiveAccountUpdate
            .sink { [weak self] account in
                self?.accountId = account?.id
                self?.clear()
            }
            .store(in: &subscriptions)
    }
    
    func notify(_ notification: PNotification) {
        guard settings.notificationsEnabled.value else { return }
        
        player?.seek(to: .zero)
        player?.play()
        
        DispatchQueue.main.async {
            self.newAlerts.value += 1
            self.alertsBeenSeen.value = false
            self.notifications.value.append(notification)
        }
    }
    
    func sendLocalNotification(title: String, body: String) {
        guard settings.notificationsEnabled.value else { return }
        // 1. Request permission
        requestAuthorization { granted in
            guard granted else { return }
            
            // 2. Create the notification content
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = UNNotificationSound.default
            
            // 3. Create a trigger for the notification
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.125, repeats: false)
            
            // 4. Create a request
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            
            // 5. Schedule the notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling local notification: \(error)")
                }
            }
        }
    }
    
    func isNotificationsEnrolled() async -> Bool {
        await UNUserNotificationCenter
            .current()
            .notificationSettings()
            .authorizationStatus == .authorized
    }
    
    func requestAuthorization(granted: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _granted, _ in
            granted(_granted)
        }
    }
    
    func markAllAlertsViewed() {
        alertsBeenSeen.value.toggle()
        newAlerts.value = 0
    }
    
    func clear() {
        newAlerts.value = 0
        notifications.value.removeAll()
    }
}
