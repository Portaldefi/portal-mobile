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
                let viewModel = Container.sendViewModel()
                
                if case .eth = item.type {
                    viewModel.coin = .ethereum()
                } else {
                    viewModel.coin = .bitcoin()
                }
                
                guard viewModel.hasAmount(item: item) else {
                    switch item.type {
                    case .bip21, .eth:
                        navigation.push(.sendSetRecipient(viewModel: viewModel), animated: false)
                    default: break
                    }
                    navigation.push(.sendSetAmount(viewModel: viewModel))
                    return
                }
                                    
                guard !viewModel.receiverAddress.isEmpty else { return }
                navigation.push(.sendSetRecipient(viewModel: viewModel), animated: false)
                switch item.type {
                case .bip21, .eth:
                    navigation.push(.sendSetAmount(viewModel: viewModel), animated: false)
                default: break
                }
                navigation.push(.sendReviewTxView(viewModel: viewModel))
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
