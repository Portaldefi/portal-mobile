//
//  SendViewViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 25/8/22.
//

import Foundation
import Factory
import BitcoinAddressValidator
import Combine

class SendViewViewModel: ObservableObject {
    var walletItems: [WalletItem] = []
    
    @Published var to = String()
    @Published var amount = String()
    @Published var qrScannerOpened = false
    @Published var showSuccessAlet = false
    @Published var showErrorAlert = false
    @Published var selectedItem: WalletItem?
    @Published var qrCodeItem: QRCodeItem?
    @Published var goToSend = false
    
    @Published private(set) var sendError: Error?
    
    private var subscriptions = Set<AnyCancellable>()
    
    @Injected(Container.accountViewModel) private var account
    
    var sendButtonEnabled: Bool {
        BitcoinAddressValidator.isValid(address: to) && (Double(amount) ?? 0) > 0
    }
    
    init() {
        self.walletItems = account.items
        
        $selectedItem.sink { [unowned self] item in
            self.goToSend = item != nil
        }
        .store(in: &subscriptions)
        
        $qrCodeItem.sink { [unowned self] item in
            guard let item = item else { return }
            switch item.type {
            case .bip21(let address, let amount, _):
                self.selectedItem = walletItems.first
                self.to = address
                guard let amount = amount else { return }
                self.amount = amount
            default:
                break
            }

        }
        .store(in: &subscriptions)
    }
    
    func send() {
        account.send(to: to, amount: amount, completion: { [weak self] error in
            guard let error = error else {
                self?.showSuccessAlet.toggle()
                return
            }
            self?.sendError = error
            self?.showErrorAlert.toggle()
        })
    }
}
