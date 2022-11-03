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
                Text("Set Recipient")
                    .font(.Main.fixed(.bold, size: 24))
                    .foregroundColor(Palette.grayScaleCA)
                
                ZStack {
                    if viewModel.recipientAddressIsValid {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 58/255, green: 58/255, blue: 58/255), lineWidth: 1)
                            .foregroundColor(Color.clear)

                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 255/255, green: 82/255, blue: 82/255), lineWidth: 1)
                            .foregroundColor(Color.clear)
                    }
                    
                    TextField("Enter address", text: $viewModel.to)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .font(.Main.fixed(.monoRegular, size: 16))
                        .foregroundColor(
                            viewModel.recipientAddressIsValid ? Palette.grayScaleAA : Color(red: 255/255, green: 82/255, blue: 82/255)
                        )
                        .padding()
                        .cornerRadius(12)
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
