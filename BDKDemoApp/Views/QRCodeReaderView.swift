//
//  QRCodeReaderView.swift
//  BDKDemoApp
//
//  Created by farid on 8/29/22.
//

import SwiftUI
import Factory

struct QRCodeReaderView: View {
    @State private var goToSend = false
    
    enum Config {
        case send, universal
    }
    
    @Injected(Container.sendViewModel) private var viewModel
    @Environment(\.presentationMode) private var presentation
    private(set) var completion: (QRCodeItem) -> ()
    private let config: Config
    
    init(config: Config, block: @escaping (QRCodeItem) -> () = { _ in } ) {
        self.config = config
        completion = block
    }
    
    var body: some View {
        NavigationView {
            VStack {
                QRCodeScannerView { item in
                    switch config {
                    case .universal:
                        viewModel.qrCodeItem = item
                        goToSend.toggle()
                    case .send:
                        completion(item)
                        presentation.wrappedValue.dismiss()
                    }
                } onClose: {
                    presentation.wrappedValue.dismiss()
                }
                
                NavigationLink(
                    destination: SendView(),
                    isActive: $goToSend
                ) {
                    EmptyView()
                }
            }
        }
        .navigationBarHidden(true)
    }
}
