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
    
    @Published private(set) var qrCode: UIImage?
    @Published private(set) var step: RecieveStep = .selectAsset
    @Published private(set) var walletItems = [WalletItem]()
    
    @Published var sharedAddress: IdentifiableString?
    @Published var selectedItem: WalletItem?
    @Published var exchanger: Exchanger?
    
    @Injected(Container.marketData) private var marketData
    
    private var subscriptions = Set<AnyCancellable>()
    
    var receiveAddress: String {
        adapter?.receiveAddress ?? "Address"
    }
    
    init(items: [WalletItem], selectedItem: WalletItem?) {
        self.walletItems = items
        self.selectedItem = selectedItem
        
        $selectedItem
            .receive(on: RunLoop.main)
            .sink { [unowned self] item in
                self.updateExchanger(coin: item?.coin)
                self.updateAdapter(coin: item?.coin)

                if let item = item {
                    withAnimation {
                        self.step = .generateQR
                    }
                    self.generateQRCode(coin: item.coin)
                } else {
                    self.step = .selectAsset
                }
        }
        .store(in: &subscriptions)
    }
    
    private func updateExchanger(coin: Coin?) {
        guard let coin = coin else {
            exchanger = nil
            return
        }
        
        let price: Decimal
        
        switch coin.type {
        case .bitcoin, .lightningBitcoin:
            price = marketData.btcTicker?[.usd].price ?? 1
        case .ethereum, .erc20:
            price = marketData.ethTicker?[.usd].price ?? 1
        }
        
        exchanger = Exchanger(
            base: coin,
            quote: .fiat(FiatCurrency(code: "USD", name: "United States Dollar", rate: 1)),
            price: price
        )
        
        guard let exchanger = exchanger else { return }
        
        Publishers.CombineLatest(exchanger.$baseAmountString, $description)
            .flatMap { _ in Just(()) }
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                self.generateQRCode(coin: exchanger.base)
            }
            .store(in: &subscriptions)
    }
    
    private func updateAdapter(coin: Coin?) {
        guard let coin = coin else {
            adapter = nil
            return
        }

        let adapterManager: IAdapterManager = Container.adapterManager()
        let walletManager: IWalletManager = Container.walletManager()
                
        guard
            let wallet = walletManager.activeWallets.first(where: { $0.coin == coin }),
            let depositAdapter = adapterManager.depositAdapter(for: wallet)
        else {
            fatalError("coudn't fetch dependencies")
        }
        
        self.adapter = depositAdapter
    }
    
    private func generateQRCode(coin: Coin) {
        guard let exchanger = exchanger else { return }
        
        var qrCodeString: String
        
        switch coin.type {
        case .bitcoin:
            qrCodeString = "bitcoin:\(receiveAddress)"
        case .ethereum:
            qrCodeString = "ethereum:\(receiveAddress)"
        default:
            qrCodeString = String()
        }
                
        var components = URLComponents()
        components.queryItems = []
        
        if exchanger.baseAmountDecimal > 0 {
            components.queryItems?.append(URLQueryItem(name: "amount", value: exchanger.baseAmountString))
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
            return
        }
        
        qrCode = UIImage(cgImage: cgimg)
    }
    
    func clear() {
        selectedItem = nil
        qrCode = UIImage()
        adapter = nil
        exchanger?.amount.string = String()
        description = String()
    }
    
    func copyToClipboard() {
        UIPasteboard.general.string = receiveAddress
    }
    
    func share() {
        guard let coin = selectedItem?.coin else { return }
        
        let description: String
        
        switch coin.type {
        case .bitcoin:
            description = "\n\nThis is a bitcoin network address. Only send BTC to this address. Do not send lightning network assets to his address."
        case .lightningBitcoin:
            description = "\n\nThis is a lightning invoice."
        case .ethereum, .erc20:
            description = "\n\nThis is an ethereum network address."
        }
        sharedAddress = IdentifiableString(text: receiveAddress + description)
    }
    
    var isIPod: Bool {
        return UIScreen.main.bounds.height == 568 && UIScreen.main.bounds.width == 320
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
