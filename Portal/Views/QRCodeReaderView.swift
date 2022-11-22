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
    @State private var goToSend = false
    
    @Environment(\.presentationMode) private var presentation
    private(set) var completion: (QRCodeItem) -> ()
    private let config: QRScannerConfig
    
    init(config: QRScannerConfig, block: @escaping (QRCodeItem) -> () = { _ in } ) {
        self.config = config
        completion = block
    }
    
    var body: some View {
        NavigationView {
            VStack {
                QRCodeScannerView(config: config) { item in
                    switch config {
                    case .universal:
                        let vm = Container.sendViewModel()
                        vm.qrCodeItem = item
                        goToSend.toggle()
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
                
                switch config {
                case .universal, .send:
                    NavigationLink(
                        destination: SendView(),
                        isActive: $goToSend
                    ) {
                        EmptyView()
                    }
                default:
                    EmptyView()
                }
            }
        }
        .navigationBarHidden(true)
    }
}
