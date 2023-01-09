//
//  ReceiveViewModel.swift
// Portal
//
//  Created by farid on 9/22/22.
//

import Foundation
import Factory
import Combine
import CoreImage.CIFilterBuiltins
import SwiftUI

class ReceiveViewModel: ObservableObject {
    enum RecieveStep {
        case selectAsset, generateQR
    }
    
    private var adapter: IDepositAdapter?
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    @Published var editingAmount = false
    
    @Published var description = String()
    @Published var editingDescription = false
    
    @Published private(set) var qrCode = UIImage()
    @Published private(set) var step: RecieveStep = .selectAsset
    @Published private(set) var walletItems = [WalletItem]()
    
    @Published var sharedAddress: IdentifiableString?
    @Published var selectedItem: WalletItem?
    @Published var exchanger: Exchanger
    
    private var subscriptions = Set<AnyCancellable>()
    
    var receiveAddress: String {
        adapter?.receiveAddress ?? String()
    }
    
    init(items: [WalletItem], selectedItem: WalletItem?) {
        self.walletItems = items
        self.selectedItem = selectedItem
        
        self.exchanger = Exchanger(
            base: .bitcoin(),
            quote: .fiat(FiatCurrency(code: "USD", name: "United States Dollar", rate: 1)),
            balance: BalanceAdapterMocked().balance
        )
        
        Publishers.CombineLatest(exchanger.baseAmount.$value, $description)
            .flatMap { _ in Just(()) }
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                self.generateQRCode()
            }
            .store(in: &subscriptions)
        
        $selectedItem
            .receive(on: RunLoop.main)
            .sink { [unowned self] item in
                self.updateAdapter()

                if item != nil {
                    withAnimation {
                        self.generateQRCode()
                        self.step = .generateQR
                    }
                } else {
                    withAnimation {
                        self.step = .selectAsset
                    }
                }
        }
        .store(in: &subscriptions)
    }
    
    private func updateAdapter() {
        guard let selectedItem = selectedItem else { return }
        
        let adapterManager: IAdapterManager = Container.adapterManager()
        let walletManager: IWalletManager = Container.walletManager()
                
        guard
            let wallet = walletManager.activeWallets.first(where: { $0.coin == selectedItem.viewModel.coin }),
            let depositAdapter = adapterManager.depositAdapter(for: wallet)
        else {
            fatalError("coudn't fetch dependencies")
        }
        
        self.adapter = depositAdapter
    }
    
    private func generateQRCode() {
        guard let adapter = adapter else { return }
        guard let selectedItem = selectedItem else { return }
        
        var qrCodeString: String
        
        switch selectedItem.viewModel.coin.type {
        case .bitcoin:
            qrCodeString = "bitcoin:\(adapter.receiveAddress)"
        case .ethereum:
            qrCodeString = "ethereum:\(adapter.receiveAddress)"
        default:
            qrCodeString = String()
        }
                
        var components = URLComponents()
        components.queryItems = []
        
        if !exchanger.baseAmount.value.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "amount", value: exchanger.baseAmount.value))
        }

        if !description.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "message", value: description))
        }
                
        if let parameters = components.string, parameters != "?" {
            qrCodeString += parameters
        }
        
        print("QR CODE STRING: \(qrCodeString)")
        
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
    
    func clear() {
        selectedItem = nil
        qrCode = UIImage()
        adapter = nil
        exchanger.baseAmount.value = String()
        description = String()
    }
    
    func copyToClipboard() {
        guard let adapter = adapter else { return }

        UIPasteboard.general.string = adapter.receiveAddress
    }
    
    func share() {
        guard let adapter = adapter else { return }
        sharedAddress = IdentifiableString(text: "\(adapter.receiveAddress)\n\nThis is a bitcoin network address. Only send BTC to this address. Do not send lightning network assets to his address.")
    }
}

extension ReceiveViewModel {
    static func config(items: [WalletItem], selectedItem: WalletItem?) -> ReceiveViewModel {
        ReceiveViewModel(items: items, selectedItem: selectedItem)
    }
    
    static var mocked: ReceiveViewModel {
        ReceiveViewModel(items: [WalletItem.mockedBtc], selectedItem: WalletItem.mockedBtc)
    }
}
