//
//  ReceiveView.swift
//  BDKDemoApp
//
//  Created by farid on 7/22/22.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import BitcoinDevKit

let context = CIContext()
let filter = CIFilter.qrCodeGenerator()

struct ReceiveView: View {
    @ObservedObject var viewModel: WalletViewModel
    @State private var address: String = "tb1qfafsasdfasd"
    
    init(viewModel: WalletViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    func getAddress() {
        switch viewModel.state {
        case .loaded(let wallet, _):
            do {
                let addressInfo = try wallet.getAddress(addressIndex: AddressIndex.lastUnused)
                address = addressInfo.address
            } catch {
                address = "ERROR"
            }
        default: do { }
        }
    }
    
    func generateQRCode(from string: String) -> UIImage {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        
        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Image(uiImage: generateQRCode(from: "bitcoin:\(address)"))
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 350)
                Spacer()
                Text(address)
                Spacer()
            }.contextMenu {
                Button(action: {
                    UIPasteboard.general.string = address}) {
                        Text("Copy to clipboard")
                    }
            }
            Spacer()
        }
        .navigationTitle("Receive Address")
        .modifier(BackButtonModifier())
        .onAppear(perform: getAddress)
    }
}

struct ReceiveView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiveView(viewModel: WalletViewModel())
    }
}
