//
//  SetRecipientView.swift
//  Portal
//
//  Created by farid on 9/12/22.
//

import SwiftUI
import PortalUI

struct SetRecipientView: View {
    @State private var textHeight : CGFloat = 60
    @ObservedObject var viewModel: SendViewViewModel
    
    init(viewModel: SendViewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Set Recipient")
                    .font(.Main.fixed(.bold, size: 24))
                    .foregroundColor(Palette.grayScaleCA)
                
                ZStack {
                    if viewModel.recipientAddressIsValid {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Palette.grayScale3A, lineWidth: 1)
                            .allowsHitTesting(false)

                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 255/255, green: 82/255, blue: 82/255), lineWidth: 1)
                            .allowsHitTesting(false)
                    }
                    
                    ZStack(alignment: .leading) {
                        TextEditor(text: $viewModel.receiverAddress)
                            .lineLimit(2)
                            .frame(height: viewModel.receiverAddress.count > 34 ? 60 : 40)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .font(.Main.fixed(.monoRegular, size: 16))
                            .foregroundColor(viewModel.recipientAddressIsValid ? .white : Color(red: 1, green: 0.349, blue: 0.349))
                            .padding(8)

                        if viewModel.receiverAddress.isEmpty {
                            Text("Enter address")
                                .font(.Main.fixed(.monoRegular, size: 16))
                                .foregroundColor(Palette.grayScale4A)
                                .padding(16)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(Color(red: 28/255, green: 28/255, blue: 30/255))
                    .frame(height: 58)
                }
                .cornerRadius(12)
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
        .navigationBarHidden(true)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .alert(isPresented: $viewModel.clipboardIsEmpty) {
            Alert(title: Text("Empty Clipboard"), message: Text("You don't have anything in your device clipboard."), dismissButton: .default(Text("OK")))
        }
    }
}

struct RecipientView_Previews: PreviewProvider {
    static var previews: some View {
        SetRecipientView(viewModel: SendViewViewModel.mocked)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
