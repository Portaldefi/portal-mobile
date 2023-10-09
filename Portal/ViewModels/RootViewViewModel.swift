//
//  RootViewViewModel.swift
// Portal
//
//  Created by farid on 8/9/22.
//

import Foundation
import Combine
import Factory

@Observable class RootViewViewModel {
    enum State {
        case account, empty
    }
    public var state: State = .empty
    
    @ObservationIgnored private var subscriptions = Set<AnyCancellable>()
    @ObservationIgnored private var manager = Container.accountManager()
    @ObservationIgnored private var settings = Container.settings()

    init() {
//        if let address = getWiFiAddress() {
//            print("Local network address: \(address)")
//            UserDefaults.standard.set(address, forKey: "LocalNetworkIpAddress")
//        }
        
        if manager.activeAccount != nil {
            state = .account
        }
        
        manager.onActiveAccountUpdate
            .receive(on: RunLoop.main)
            .sink { [unowned self] account in
                guard account != nil, state != .account else { return }
                state = .account
            }
            .store(in: &subscriptions)
    }
    
    func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: ifaddr, next: { $0?.pointee.ifa_next }) {
            guard
                let interface = ptr?.pointee.ifa_name,
                let addr = ptr?.pointee.ifa_addr,
                addr.pointee.sa_family == UInt8(AF_INET),
                String(cString: interface) == "en0"
            else { continue }

            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
            address = String(cString: hostname)
        }

        return address
    }
}
