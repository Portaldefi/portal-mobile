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
    @ObservedObject var viewModel: AccountViewModel
    @State private var address: String = String()
    @State private var qrCode: UIImage = UIImage()
    
    init(viewModel: AccountViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Image(uiImage: qrCode)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 350)
                Spacer()
                Text(address)
                Spacer()
                Button {
                    address = viewModel.getAddress(new: true)
                    qrCode = viewModel.generateQRCode(from: "bitcoin:\(address)")
                } label: {
                    Text("Generate new address")
                        .foregroundColor(.black)
                        .font(.system(size: 16, design: .monospaced))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.blue)
                        .background(in: RoundedRectangle(cornerRadius: 10))
                        .frame(height: 50)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .padding()
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
        .onAppear(perform: {
            address = viewModel.getAddress()
            qrCode = viewModel.generateQRCode(from: "bitcoin:\(address)")
        })
    }
}

struct ReceiveView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiveView(viewModel: AccountViewModel())
    }
}
