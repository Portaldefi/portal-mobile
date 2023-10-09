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

struct QRCodeSharedItem: Identifiable {
    let id = UUID()
    let name: String
    let displayedItem: String
    let item: String
}

@Observable class ReceiveViewModel {
    enum RecieveStep {
        case selectAsset, generateQR
    }
    
    @ObservationIgnored private var adapter: IDepositAdapter?
    
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    
    public var editingAmount = false
    
    public var description = String() {
        didSet {
            description$.send(description)
        }
    }
    @ObservationIgnored private var description$ = CurrentValueSubject<String, Never>(String())

    public var editingDescription = false
    public var showConfirmationOnCopy = false
    public var showNetworkSelector = false
    public var showFullQRCodeString = false
    public var onAmountChange = false {
        didSet {
            onAmountChange$.send(onAmountChange)
        }
    }
    @ObservationIgnored private var onAmountChange$ = CurrentValueSubject<Bool, Never>(false)
    
    private(set) var qrCode: UIImage?
    private(set) var walletItems = [WalletItem]()
    
    public var sharedAddress: IdentifiableString?
    
    @ObservationIgnored public var selectedItem: WalletItem? {
        didSet {
            guard let item = selectedItem else { return }
            updateExchanger(coin: item.coin)
            updateAdapter(coin: item.coin)
        }
    }
    @ObservationIgnored public var exchanger: Exchanger?
    @ObservationIgnored public var qrAddressType: BTCQRCodeAddressType = .lightning {
        didSet {
            qrAddressType$.send(qrAddressType)
        }
    }
    @ObservationIgnored private var qrAddressType$ = CurrentValueSubject<BTCQRCodeAddressType, Never>(.lightning)
    
    public var invoiceString = String()
    public var sharedItems: [QRCodeSharedItem] = []
    public var sharedItem: QRCodeSharedItem?
    
    @ObservationIgnored private var marketData = Container.marketData()
    @ObservationIgnored private var settings = Container.settings()
    @ObservationIgnored private var lightningKit = Container.lightningKitManager()
    
    @ObservationIgnored private var subscriptions = Set<AnyCancellable>()
    
    var fiatCurrency: FiatCurrency {
        settings.fiatCurrency.value
    }
    
    var receiveAddress: String {
        adapter?.receiveAddress ?? "Address"
    }
    
    init(items: [WalletItem], selectedItem: WalletItem?) {
        self.walletItems = items
        self.selectedItem = selectedItem
        
        guard let item = selectedItem else { return }
        updateExchanger(coin: item.coin)
        updateAdapter(coin: item.coin)
    }
    
    private func updateExchanger(coin: Coin?) {
        guard let coin = coin else {
            exchanger = nil
            return
        }
        
        let price: Decimal
        
        switch coin.type {
        case .bitcoin, .lightningBitcoin:
            price = marketData.lastSeenBtcPrice * fiatCurrency.rate
        case .ethereum:
            price = marketData.lastSeenEthPrice * fiatCurrency.rate
            qrAddressType = .onChain
        case .erc20(let address):
            if address == "0x326C977E6efc84E512bB9C30f76E30c160eD06FB" {
                price = marketData.lastSeenLinkPrice * fiatCurrency.rate
                qrAddressType = .onChain
            } else {
                price = 0
            }
        }
        
        exchanger = Exchanger(
            base: coin,
            quote: .fiat(fiatCurrency),
            price: price
        )
        
        guard let exchanger = exchanger else { return }
        
        Publishers.CombineLatest3(onAmountChange$, description$, qrAddressType$)
            .flatMap { _ in Just(()) }
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                switch qrAddressType {
                case .onChain:
                    let addressString = adapter?.receiveAddress ?? "Unknown address"
                    let displayedAddress = addressString.groupedByThree.uppercased()
                    self.sharedItems = [QRCodeSharedItem(name: "On Chain Address", displayedItem: displayedAddress, item: addressString)]
                    self.generateQRCode(coin: exchanger.base)
                case .lightning:
                    qrCode = nil
                    
                    Task {
                        let invoice = await self.lightningKit.createInvoice(amount: exchanger.baseAmountString, description: self.description)
                        
                        DispatchQueue.main.async {
                            self.invoiceString = invoice ?? String()
                            self.generateQRCode(coin: exchanger.base)
                            self.sharedItems = [QRCodeSharedItem(name: "Lightning Invoice", displayedItem: self.invoiceString.turnicated.uppercased(), item: self.invoiceString)]
                        }
                    }
                case .unified:
                    qrCode = nil
                    
                    Task {
                        let invoice = await self.lightningKit.createInvoice(amount: exchanger.baseAmountString, description: self.description)
                        
                        DispatchQueue.main.async {
                            self.invoiceString = invoice ?? String()
                            self.generateQRCode(coin: exchanger.base)
                            
                            let addressString = self.adapter?.receiveAddress ?? "Unknown address"
                            let displayedAddress = addressString.groupedByThree.uppercased()
                            let addressItem = QRCodeSharedItem(name: "On Chain Address", displayedItem: displayedAddress, item: addressString)
                            let invoiceItem = QRCodeSharedItem(name: "Lightning Invoice", displayedItem: self.invoiceString.turnicated.uppercased(), item: self.invoiceString)
                            
                            self.sharedItems = [addressItem, invoiceItem]
                        }
                    }
                }
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
                qrCodeString = "lightning:\(invoiceString)"
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
                
                qrCodeString += "&lightning:\(invoiceString)"
            }
        case .ethereum:
            qrCodeString = "ethereum:\(receiveAddress)"
            
            if let components = pathComponents() {
                qrCodeString += components
            }
        case .erc20:
            qrCodeString = "link:\(receiveAddress)"
            
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
        if let item = sharedItem?.item {
            UIPasteboard.general.string = item
            showConfirmationOnCopy.toggle()
        }
    }
    
    func share() {
        guard let coin = selectedItem?.coin else { return }
        
        let description: String
        
        switch coin.type {
        case .bitcoin:
            switch qrAddressType {
            case .lightning:
                description = "\n\nThis is a lightning invoice."
                sharedAddress = IdentifiableString(text: receiveAddress + description)
            case .onChain:
                description = "\n\nThis is a bitcoin network address. Only send BTC to this address. Do not send lightning network assets to his address."
                sharedAddress = IdentifiableString(text: receiveAddress + description)
            case .unified:
                description = "\n\nThis is a bitcoin network address. Only send BTC to this address. Do not send lightning network assets to his address."
                let description2 = "\n\nThis is a lightning invoice."
                sharedAddress = IdentifiableString(text: receiveAddress + description + description2)
            }
        case .lightningBitcoin:
            description = "\n\nThis is a lightning invoice."
            sharedAddress = IdentifiableString(text: receiveAddress + description)
        case .ethereum, .erc20:
            description = "\n\nThis is an ethereum network address."
            sharedAddress = IdentifiableString(text: receiveAddress + description)
        }
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
