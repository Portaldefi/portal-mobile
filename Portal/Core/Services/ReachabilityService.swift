//
//  ReachabilityService.swift
//  Portal
//
//  Created by Farid on 21.10.2021.
//

import Network
import Combine

class ReachabilityService: IReachabilityService {
    private let monitorForWifi = NWPathMonitor(requiredInterfaceType: .wifi)
    private let monitorForCellular = NWPathMonitor(requiredInterfaceType: .cellular)
    private let monitorForOtherConnections = NWPathMonitor(requiredInterfaceType: .other)
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")
    private var subscriptions = Set<AnyCancellable>()

    private var wifiStatus: NWPath.Status = .requiresConnection {
        didSet {
            isReachableOnWifi.value = wifiStatus == .satisfied
        }
    }
    private var cellularStatus: NWPath.Status = .requiresConnection {
        didSet {
            isReachableOnCellular.value = cellularStatus == .satisfied
        }
    }
    private var otherConnectionsStatus: NWPath.Status = .requiresConnection {
        didSet {
            isReachableOnOtherConnection.value = otherConnectionsStatus == .satisfied
        }
    }
    
    private var isReachableOnWifi = CurrentValueSubject<Bool, Never>(false)
    private var isReachableOnCellular = CurrentValueSubject<Bool, Never>(false)
    private var isReachableOnOtherConnection = CurrentValueSubject<Bool, Never>(false)
    private(set) var isReachable = CurrentValueSubject<Bool, Never>(false)
    
    func startMonitoring() {
        monitorForWifi.pathUpdateHandler = { [unowned self] path in
            self.wifiStatus = path.status
        }
        monitorForCellular.pathUpdateHandler = { [unowned self] path in
            self.cellularStatus = path.status
        }
        
        monitorForOtherConnections.pathUpdateHandler = { [unowned self] path in
            self.otherConnectionsStatus = path.status
        }
        
        Publishers.Merge3(isReachableOnWifi, isReachableOnCellular, isReachableOnOtherConnection)
            .sink { [unowned self] output in
                self.isReachable.value = output
            }
            .store(in: &subscriptions)
        
        monitorForCellular.start(queue: monitorQueue)
        monitorForWifi.start(queue: monitorQueue)
        monitorForOtherConnections.start(queue: monitorQueue)
    }

    func stopMonitoring() {
        monitorForWifi.cancel()
        monitorForCellular.cancel()
        monitorForOtherConnections.cancel()
    }
}
