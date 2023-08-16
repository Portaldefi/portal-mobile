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
            isReachableOnWifi.send(wifiStatus == .satisfied)
        }
    }
    private var cellularStatus: NWPath.Status = .requiresConnection {
        didSet {
            isReachableOnCellular.send(cellularStatus == .satisfied)
        }
    }
    private var otherConnectionsStatus: NWPath.Status = .requiresConnection {
        didSet {
            isReachableOnOtherConnection.send(otherConnectionsStatus == .satisfied)
        }
    }
    
    private var isReachableOnWifi = PassthroughSubject<Bool, Never>()
    private var isReachableOnCellular = PassthroughSubject<Bool, Never>()
    private var isReachableOnOtherConnection = PassthroughSubject<Bool, Never>()
    private(set) var isReachable = CurrentValueSubject<Bool, Never>(false)
    
    func startMonitoring() {
        monitorForWifi.pathUpdateHandler = { [unowned self] path in
            wifiStatus = path.status
        }
        
        monitorForCellular.pathUpdateHandler = { [unowned self] path in
            cellularStatus = path.status
        }
        
        monitorForOtherConnections.pathUpdateHandler = { [unowned self] path in
            otherConnectionsStatus = path.status
        }
        
        Publishers.CombineLatest3(isReachableOnWifi, isReachableOnCellular, isReachableOnOtherConnection)
            .sink { [unowned self] wifiAvaliable, cellularAvaliable, otherConnectionAvaliable in
                isReachable.value = wifiAvaliable || cellularAvaliable || otherConnectionAvaliable
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
        subscriptions.removeAll()
    }
}

extension ReachabilityService {
    static func mocked(hasConnection: Bool) -> IReachabilityService {
        ReachabilityServiceMocked(hasConnection: hasConnection)
    }
}

struct ReachabilityServiceMocked: IReachabilityService {
    var isReachable = CurrentValueSubject<Bool, Never>(false)
    
    func startMonitoring() {
        
    }
    
    func stopMonitoring() {
        
    }
    
    init(hasConnection: Bool) {
        isReachable.send(hasConnection)
    }
}
