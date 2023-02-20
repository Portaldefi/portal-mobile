//
//  SetRecipientView.swift
//  Portal
//
//  Created by farid on 9/12/22.
//

import SwiftUI
import PortalUI

struct SetRecipientView: View {
    @State private var textHeight: CGFloat = 60
    @State private var showScanner = false
    @ObservedObject var viewModel: SendViewViewModel
    @EnvironmentObject private var navigation: NavigationStack
    @Environment(\.presentationMode) private var presentationMode
    
    let rootView: Bool
            
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        PButton(config: rootView ? .onlyIcon(Asset.xIcon) : .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                            if rootView {
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                viewModel.clearRecipient()
                                navigation.pop()
                            }
                        }
                        .frame(width: 20)
                        
                        Spacer()
                    }
                    
                    Text("Send")
                        .frame(width: 300, height: 62)
                        .font(.Main.fixed(.monoBold, size: 16))
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Set Recipient")
                            .font(.Main.fixed(.bold, size: 24))
                            .foregroundColor(Palette.grayScaleCA)
                        
                        ZStack {
                            if viewModel.sendError == nil {
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
                                    .hideBackground()
                                    .lineLimit(2)
                                    .frame(height: viewModel.receiverAddress.count > 34 ? 60 : 40)
                                    .disableAutocorrection(true)
                                    .textInputAutocapitalization(.never)
                                    .font(.Main.fixed(.monoRegular, size: 16))
                                    .foregroundColor(viewModel.sendError == nil ? .white : Color(red: 1, green: 0.349, blue: 0.349))
                                    .padding(8)

                                if viewModel.receiverAddress.isEmpty {
                                    Text("Enter address")
                                        .font(.Main.fixed(.monoRegular, size: 16))
                                        .foregroundColor(Palette.grayScale4A)
                                        .padding(16)
                                        .allowsHitTesting(false)
                                }
                            }
                            .frame(height: 58)
                        }
                        .cornerRadius(12)
                        .frame(height: 58)
                    }
                    
                    HStack(spacing: 16) {
                        PButton(
                            config: .labelAndIconLeft(label: "Scan", icon: Asset.scanIcon),
                            style: .outline,
                            size: .medium,
                            enabled: true
                        ) {
                            showScanner.toggle()
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
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                Divider()
                    .frame(height: 1)
                    .overlay(Palette.grayScale4A)
                
                VStack(alignment: .leading, spacing: 16) {
                    if let errorMessage = viewModel.sendError as? SendFlowError {
                        Text(errorMessage.description)
                            .font(.Main.fixed(.monoRegular, size: 16))
                            .foregroundColor(Color(red: 255/255, green: 82/255, blue: 82/255))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    PButton(
                        config: .onlyLabel("Continue"),
                        style: .filled,
                        size: .big,
                        enabled: !viewModel.receiverAddress.isEmpty && viewModel.sendError == nil
                    ) {
                        withAnimation {
                            viewModel.validateReceiverAddress()
                        }
                        
                        if viewModel.sendError == nil {
                            navigation.push(.sendSetAmount(viewModel: viewModel))
                        }
                    }
                }
                .padding(16)
            }
            .background(
                Palette.grayScale2A.edgesIgnoringSafeArea(.bottom)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(1)

        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .alert(isPresented: $viewModel.clipboardIsEmpty) {
            Alert(title: Text("Empty Clipboard"), message: Text("You don't have anything in your device clipboard."), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showScanner) {
            if let coin = viewModel.coin {
                QRCodeReaderView(config: .send(coin)) { item in
                    let address: String
                    let amount: String?
                    
                    switch item.type {
                    case .bip21(let adr, let amt, _):
                        address = adr
                        amount = amt
                    case .eth(let adr, let amt, _):
                        address = adr
                        amount = amt
                    default:
                        address = String()
                        amount = nil
                    }
                    
                    viewModel.receiverAddress = address
                    
                    guard let amt = amount else {
                        navigation.push(.sendSetAmount(viewModel: viewModel))
                        return
                    }
                    
                    viewModel.exchanger?.amount.string = amt
                    
                    navigation.push(.sendSetAmount(viewModel: viewModel))
                    navigation.push(.sendReviewTxView(viewModel: viewModel))
                }
            }
        }
    }
}

extension TextEditor {
    @ViewBuilder func hideBackground() -> some View {
        if #available(iOS 16, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}

import Factory

struct RecipientView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.walletManager.register { WalletManager.mocked }
        let _ = Container.adapterManager.register { AdapterManager.mocked }
        
        SetRecipientView(viewModel: SendViewViewModel.mocked, rootView: true)
    }
}
