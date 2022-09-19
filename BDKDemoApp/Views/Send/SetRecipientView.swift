//
//  SetRecipientView.swift
//  BDKDemoApp
//
//  Created by farid on 9/12/22.
//

import SwiftUI
import PortalUI

struct SetRecipientView: View {
    @ObservedObject var viewModel: SendViewViewModel
    
    init(viewModel: SendViewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose Recipient")
                    .font(.Main.fixed(.bold, size: 24))
                    .foregroundColor(Palette.grayScaleCA)
                
                TextField("Enter address", text: $viewModel.to)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .font(.Main.fixed(.regular, size: 16))
                    .foregroundColor(
                        viewModel.recipientAddressIsValid ? Palette.grayScaleAA : Color(red: 255/255, green: 82/255, blue: 82/255)
                    )
                    .padding()
                    .background(Palette.grayScale1A)
                    .cornerRadius(12)
                    .if(!viewModel.recipientAddressIsValid, then: { textField in
                        textField
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 255/255, green: 82/255, blue: 82/255), lineWidth: 2)
                                    .foregroundColor(Color.clear)
                            )
                    })
                
                    if let errorMessage = viewModel.sendError as? SendFlowError {
                        Text(errorMessage.description)
                            .font(.Main.fixed(.regular, size: 16))
                            .foregroundColor(Color(red: 255/255, green: 82/255, blue: 82/255))
                            .transition(.scale.combined(with: .opacity))
                    }
            }
            
            HStack(spacing: 16) {
                PButton(
                    config: .labelAndIconLeft(label: "Scan", icon: Asset.scanIcon),
                    style: .outline,
                    size: .medium,
                    enabled: true
                ) {
                    viewModel.openScanner()
                }
                
                PButton(
                    config: .labelAndIconLeft(label: "Paste", icon: Asset.pasteIcon),
                    style: .outline,
                    size: .medium,
                    enabled: true
                ) {
                    viewModel.pasteFromClipboard()
                }
            }
        }
        .sheet(isPresented: $viewModel.qrScannerOpened, onDismiss: {
            viewModel.qrScannerOpened = false
        }) {
            QRCodeReaderView(config: .send) { item in
                switch item.type {
                case .bip21(let address, let amount, _):
                    viewModel.to = address
                    guard let _amount = amount else { return }
                    viewModel.exchanger.cryptoAmount = _amount
                    withAnimation {
                        viewModel.toReview()
                    }
                default:
                    break
                }
            }
        }
    }
}

struct RecipientView_Previews: PreviewProvider {
    static var previews: some View {
        SetRecipientView(viewModel: SendViewViewModel.mocked)
    }
}
