//
//  NotificationService.swift
//  Portal
//
//  Created by Farid on 28.06.2021.
//

import Foundation
import AVFoundation
import Combine

final class NotificationService: ObservableObject {
    private let player: AVPlayer?
    
    private(set) var notifications = CurrentValueSubject<[PNotification], Never>([])
    private(set) var newAlerts = CurrentValueSubject<Int, Never>(0)
    private(set) var alertsBeenSeen = CurrentValueSubject<Bool, Never>(false)
    
    private var accountId: String?
    private var subscriptions = Set<AnyCancellable>()
        
    init(accountManager: IAccountManager) {
        if let url = Bundle.main.url(forResource: "alert", withExtension: "mp3") {
            player = AVPlayer.init(url: url)
        } else {
            player = nil
        }
        
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
        player?.seek(to: .zero)
        player?.play()
        
        DispatchQueue.main.async {
            self.newAlerts.value += 1
            self.alertsBeenSeen.value = false
            self.notifications.value.append(notification)
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
