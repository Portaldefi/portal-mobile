//
//  QRCodeReaderView.swift
// Portal
//
//  Created by farid on 8/29/22.
//

import SwiftUI
import Factory

enum QRScannerConfig: Equatable {
    case send(Coin), universal, importing
}

struct QRCodeReaderView: View {
    @Environment(\.presentationMode) private var presentation
    @EnvironmentObject private var navigation: NavigationStack

    private(set) var completion: (QRCodeItem) -> ()
    private let config: QRScannerConfig
    
    init(config: QRScannerConfig, block: @escaping (QRCodeItem) -> () = { _ in } ) {
        self.config = config
        completion = block
    }
    
    var body: some View {
        QRCodeScannerView(config: config) { item in
            switch config {
            case .universal:
                let vm = Container.sendViewModel()
                vm.qrCodeItem = item
            
                let address: String
                let amount: String?
                
                switch item.type {
                case .bip21(let adr, let amt, _):
                    address = adr
                    amount = amt
                    vm.coin = .bitcoin()
                case .eth(let adr, let amt, _):
                    address = adr
                    amount = amt
                    vm.coin = .ethereum()
                default:
                    address = String()
                    amount = nil
                }
                
                vm.receiverAddress = address
                
                guard let amt = amount else {
                    navigation.push(.sendSetRecipient(viewModel: vm), animated: false)
                    navigation.push(.sendSetAmount(viewModel: vm))
                    return
                }
                
                vm.exchanger?.amount.string = amt
                
                navigation.push(.sendSetRecipient(viewModel: vm), animated: false)
                navigation.push(.sendSetAmount(viewModel: vm), animated: false)
                navigation.push(.sendReviewTxView(viewModel: vm))
            case .send:
                completion(item)
                presentation.wrappedValue.dismiss()
            case .importing:
                completion(item)
                presentation.wrappedValue.dismiss()
            }
        } onClose: {
            presentation.wrappedValue.dismiss()
        }
    }
}
