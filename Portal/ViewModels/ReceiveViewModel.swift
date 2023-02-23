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
    @Published var showConfirmationOnCopy = false
    @Published var showNetworkSelector = false
    @Published var showFullQRCodeString = false
    @Published var onAmountChange = false
    
    @Published private(set) var qrCode: UIImage?
    @Published private(set) var walletItems = [WalletItem]()
    
    @Published var sharedAddress: IdentifiableString?
    @Published var selectedItem: WalletItem?
    @Published var exchanger: Exchanger?
    @Published var qrAddressType: BTCQRCodeAddressType = .lightning
    
    @Injected(Container.marketData) private var marketData
    
    private var subscriptions = Set<AnyCancellable>()
    
    var receiveAddress: String {
        // temp impl
        switch qrAddressType {
        case .lightning:
            return "LNBC10U1P3PJ257PP5YZTKWJCZ5FTL5LAXKAV23ZMZEKAW37ZK6KMV80PK4XAEV5QHTZ7QDPDWD3XGER9WD5KWM36YPRX7U3QD36KUCMGYP282ETNV3SHJCQZPGXQYZ5VQSP5USYC4LK9CHSFP53KVCNVQ456GANH60D89REYKDNGSMTJ6YW3NHVQ9QYYSSQJCEWM5CJWZ4A6RFJX77C490YCED6PEMK0UPKXHY89CMM7SCT66K8GNEANWYKZGDRWRFJE69H9U5U0W57RRCSYSAS7GADWMZXC8C6T0SPJAZUP6"
        case .onChain:
            return adapter?.receiveAddress ?? "Address"
        case .unified:
            return adapter?.receiveAddress ?? "Address" + "\n" + "LNBC10U1P3PJ257PP5YZTKWJCZ5FTL5LAXKAV23ZMZEKAW37ZK6KMV80PK4XAEV5QHTZ7QDPDWD3XGER9WD5KWM36YPRX7U3QD36KUCMGYP282ETNV3SHJCQZPGXQYZ5VQSP5USYC4LK9CHSFP53KVCNVQ456GANH60D89REYKDNGSMTJ6YW3NHVQ9QYYSSQJCEWM5CJWZ4A6RFJX77C490YCED6PEMK0UPKXHY89CMM7SCT66K8GNEANWYKZGDRWRFJE69H9U5U0W57RRCSYSAS7GADWMZXC8C6T0SPJAZUP6"
        }
    }
    
    var displayedString: String {
        switch qrAddressType {
        case .lightning:
            return receiveAddress.turnicated.uppercased()
        case .onChain:
            return receiveAddress.groupedByThree.uppercased()
        case .unified:
            return receiveAddress
        }
    }
    
    init(items: [WalletItem], selectedItem: WalletItem?) {
        self.walletItems = items
        self.selectedItem = selectedItem
        
        $selectedItem
            .compactMap{ $0 }
            .receive(on: RunLoop.main)
            .sink { [unowned self] item in
                self.updateExchanger(coin: item.coin)
                self.updateAdapter(coin: item.coin)

                self.generateQRCode(coin: item.coin)
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
        
        Publishers.CombineLatest3($onAmountChange, $description, $qrAddressType)
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
        var qrCodeString: String
        
        switch coin.type {
        case .bitcoin:
            switch qrAddressType {
            case .lightning:
                qrCodeString = "lightning=LNBC10U1P3PJ257PP5YZTKWJCZ5FTL5LAXKAV23ZMZEKAW37ZK6KMV80PK4XAEV5QHTZ7QDPDWD3XGER9WD5KWM36YPRX7U3QD36KUCMGYP282ETNV3SHJCQZPGXQYZ5VQSP5USYC4LK9CHSFP53KVCNVQ456GANH60D89REYKDNGSMTJ6YW3NHVQ9QYYSSQJCEWM5CJWZ4A6RFJX77C490YCED6PEMK0UPKXHY89CMM7SCT66K8GNEANWYKZGDRWRFJE69H9U5U0W57RRCSYSAS7GADWMZXC8C6T0SPJAZUP6"
            case .onChain:
                qrCodeString = "bitcoin:\(receiveAddress)"
                
                if let components = pathComponents() {
                    qrCodeString += components
                }
            case .unified:
                qrCodeString = "bitcoin:\(receiveAddress)"
                
                if let components = pathComponents() {
                    qrCodeString += components
                }
                
                qrCodeString += "&lightning=LNBC10U1P3PJ257PP5YZTKWJCZ5FTL5LAXKAV23ZMZEKAW37ZK6KMV80PK4XAEV5QHTZ7QDPDWD3XGER9WD5KWM36YPRX7U3QD36KUCMGYP282ETNV3SHJCQZPGXQYZ5VQSP5USYC4LK9CHSFP53KVCNVQ456GANH60D89REYKDNGSMTJ6YW3NHVQ9QYYSSQJCEWM5CJWZ4A6RFJX77C490YCED6PEMK0UPKXHY89CMM7SCT66K8GNEANWYKZGDRWRFJE69H9U5U0W57RRCSYSAS7GADWMZXC8C6T0SPJAZUP6"
            }
        case .ethereum:
            qrCodeString = "ethereum:\(receiveAddress)"
            
            if let components = pathComponents() {
                qrCodeString += components
            }
        default:
            qrCodeString = String()
        }
        
        print("QR CODE STRING: \n\(qrCodeString)\n")
        
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
    
    private func pathComponents() -> String? {
        guard let exchanger = exchanger else { return nil }

        var components = URLComponents()
        components.queryItems = []
        
        if exchanger.baseAmountDecimal > 0 {
            components.queryItems?.append(URLQueryItem(name: "amount", value: exchanger.baseAmountString))
        }

        if !description.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "message", value: description))
        }
                
        if let parameters = components.string, parameters != "?" {
            return parameters
        }
        
        return nil
    }
    
    func copyToClipboard() {
        UIPasteboard.general.string = receiveAddress
        showConfirmationOnCopy.toggle()
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
