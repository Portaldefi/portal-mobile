//
//  ReceiveViewModel.swift
//  BDKDemoApp
//
//  Created by farid on 9/22/22.
//

import Foundation
import Factory
import Combine
import CoreImage.CIFilterBuiltins
import SwiftUI

class ReceiveViewModel: ObservableObject {
    private let adapter: IDepositAdapter
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    @Published var amount = String()
    @Published var editingAmount = false
    
    @Published var description = String()
    @Published var editingDescription = false
    
    @Published private(set) var qrCode = UIImage()
    
    var receiveAddress: String {
        adapter.receiveAddress
    }
    
    init(depositAdapter: IDepositAdapter) {
        adapter = depositAdapter
        generateQRCode()
    }
    
    private func generateQRCode() {
        let qrCodeString = "bitcoin:\(adapter.receiveAddress)"
        let data = Data(qrCodeString.utf8)
        filter.setValue(data, forKey: "inputMessage")

        guard
            let outputImage = filter.outputImage,
            let cgimg = context.createCGImage(outputImage, from: outputImage.extent)
        else {
            qrCode = UIImage(systemName: "xmark.circle") ?? UIImage()
            return
        }
        
        qrCode = UIImage(cgImage: cgimg)
    }
    
    func copyToClipboard() {
        UIPasteboard.general.string = adapter.receiveAddress
    }
}

extension ReceiveViewModel {
    static func config(coin: Coin) -> ReceiveViewModel {
        let adapterManager: IAdapterManager = Container.adapterManager()
        let walletManager: IWalletManager = Container.walletManager()
                
        guard
            let wallet = walletManager.activeWallets.first(where: { $0.coin == coin }),
            let depositAdapter = adapterManager.depositAdapter(for: wallet)
        else {
            fatalError("coudn't fetch dependencies")
        }
        
        return ReceiveViewModel(depositAdapter: depositAdapter)
    }
    
    static var mocked: ReceiveViewModel {
        ReceiveViewModel(depositAdapter: DepositAdapterMocked())
    }
}
