//
//  SendViewViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 25/8/22.
//

import Foundation
import Factory
import BitcoinAddressValidator

class SendViewViewModel: ObservableObject {
    let qrCodeItem: QRCodeItem?
    var walletItems: [WalletItem] = []
    
    @Published var to = String()
    @Published var amount = String()
    @Published var qrScannerOpened = false
    @Published var showSuccessAlet = false
    @Published var showErrorAlert = false
    @Published var selectedItem: WalletItem?
    
    @Published private(set) var sendError: Error?
    
    @Injected(Container.accountViewModel) private var account
    
    var sendButtonEnabled: Bool {
        BitcoinAddressValidator.isValid(address: to) && (Double(amount) ?? 0) > 0
    }
    
    init(qrCodeItem: QRCodeItem?) {
        self.qrCodeItem = qrCodeItem
        
        switch qrCodeItem?.type {
        case .bip21(let address, let amount, _):
            selectedItem = walletItems.first
            to = address
            guard let amount = amount else { return }
            self.amount = amount
        default:
            break
        }
        
        self.walletItems = account.items
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
