//
//  INotificationService.swift
//  Portal
//
//  Created by farid on 1/20/22.
//

import Foundation
import Combine

struct PNotification: Hashable {
    let id = UUID()
    let date = Date()
    let message: String
}

protocol INotificationService {
    var notifications: CurrentValueSubject<[PNotification], Never> { get }
    var newAlerts: CurrentValueSubject<Int, Never> { get }
    var alertsBeenSeen: CurrentValueSubject<Bool, Never> { get }
    func notify(_ notification: PNotification)
    func markAllAlertsViewed()
    func clear()
}
