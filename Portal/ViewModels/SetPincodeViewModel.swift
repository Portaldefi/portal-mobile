//
//  SetPincodeViewModel.swift
//  Portal
//
//  Created by farid on 27.06.2023.
//

import Foundation
import Factory
import Combine
import SwiftUI

class SetPincodeViewModel: ObservableObject {
    private let pinLength = 4
    private var subscriptions = Set<AnyCancellable>()

    enum PinState {
        case choose, confirm, notMatched
    }
    
    @Injected(Container.settings) private var settings
    @Injected(Container.secureStorage) private var storage

    @Published private(set) var pin = String()
    @Published private(set) var pinConfirmation = String()

    @Published private(set) var title = String()
    @Published private(set) var subTitle = String()
    @Published private(set) var state: PinState = .choose
    @Published private(set) var pinIsSet = false
        
    init() {
        $pin.dropFirst().delay(for: 0.2, scheduler: RunLoop.main).sink { [unowned self] pin in
            withAnimation {
                guard !pin.isEmpty else {
                    self.state = .choose
                    return
                }
                guard pin.count == pinLength else { return }
                self.state = .confirm
            }
        }
        .store(in: &subscriptions)
        
        $pinConfirmation.delay(for: 0.2, scheduler: RunLoop.main).sink { [unowned self] pinConfirmation in
            withAnimation {
                guard pinConfirmation.count == pinLength else { return }
                if pinConfirmation == pin {
                    self.storage.save(string: pin, key: "PIN")
                    self.settings.updatePinCodeSetting(enabled: true)
                    self.pinIsSet = true
                } else {
                    self.pinConfirmation.removeAll()
                    self.state = .notMatched
                }
            }
        }
        .store(in: &subscriptions)
        
        $state.delay(for: 0.8, scheduler: RunLoop.main).sink { [unowned self] state in
            withAnimation {
                if state == .notMatched {
                    self.state = .confirm
                }
            }
        }
        .store(in: &subscriptions)
    }
    
    func add(digit: Int) {
        guard !pinIsSet else { return }
        
        withAnimation(.easeInOut(duration: 0.1)) {
            switch state {
            case .choose:
                guard pin.count < pinLength else { return }
                pin.append(String(digit))
            case .confirm, .notMatched:
                guard pinConfirmation.count < pinLength else { return }
                pinConfirmation.append(String(digit))
            }
        }
    }
    
    func removeLast() {
        guard !pinIsSet else { return }

        withAnimation(.easeInOut(duration: 0.1)) {
            switch state {
            case .choose:
                if !pin.isEmpty {
                    pin.removeLast()
                }
            case .confirm, .notMatched:
                if !pinConfirmation.isEmpty {
                    pinConfirmation.removeLast()
                }
            }
        }
    }
}
