//
//  SetRecipientView.swift
//  Portal
//
//  Created by farid on 9/12/22.
//

import SwiftUI
import PortalUI

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = value + nextValue()
    }
}

struct SetRecipientView: View {
    @State private var showScanner = false
    @State var textEditorHeight : CGFloat = 0
    @ObservedObject var viewModel: SendViewViewModel
    @EnvironmentObject private var navigation: NavigationStack
    @Environment(\.presentationMode) private var presentationMode
    
    let rootView: Bool
    
    private var textEditorColor: Color {
        guard viewModel.sendError == nil else {
            return Color(red: 255/255, green: 82/255, blue: 82/255)
        }
        return Palette.grayScale3A
    }
    
    private var textEditorInputColor: Color {
        guard viewModel.sendError == nil else {
            return Color(red: 255/255, green: 82/255, blue: 82/255)
        }
        return .white
    }
    
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
                        
                        ZStack(alignment: .leading) {
                            // Workaround issue with TextEditor being resized wrong on going back in navigation stack
                            // .fixedSize(horizontal: false, vertical: true)
                            Text(viewModel.receiverAddress)
                                .font(.Main.fixed(.monoRegular, size: 16))
                                .foregroundColor(.clear)
                                .padding(10)
                                .background(
                                    GeometryReader {
                                        Color.clear.preference(
                                            key: ViewHeightKey.self,
                                            value: $0.frame(in: .local).size.height + 4
                                        )
                                    }
                                )
                            //
                            
                            TextEditor(text: $viewModel.receiverAddress)
                                .hideBackground()
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .font(.Main.fixed(.monoRegular, size: 16))
                                .foregroundColor(textEditorInputColor)
                                .frame(height: max(40, textEditorHeight))
                                .padding(8)
                            
                            if viewModel.receiverAddress.isEmpty {
                                Text("Enter address")
                                    .font(.Main.fixed(.monoRegular, size: 16))
                                    .foregroundColor(Palette.grayScale4A)
                                    .padding(16)
                                    .allowsHitTesting(false)
                            }
                        }
                        .onPreferenceChange(ViewHeightKey.self) {
                            textEditorHeight = $0
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(textEditorColor, lineWidth: 1)
                                .allowsHitTesting(false)
                        )
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

                        //Apparently SwiftUI button has an animation issue on TextField resizing. Recreating PButton view without wrapping into SwiftUI Button
                        
                        HStack(spacing: 6) {
                            Asset.pasteIcon
                                .resizable()
                                .frame(width: 26, height: 26)
                            Text("Paste")
                                .font(.Main.fixed(.monoBold, size: 16))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(RadialGradient.main, lineWidth: 2)
                        )
                        .containerShape(Rectangle())
                        .onTapGesture {
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
                        do {
                            let result = try viewModel.validateInput()
                            
                            switch result {
                            case .btcOnChain, .ethOnChain:
                                navigation.push(.sendSetAmount(viewModel: viewModel))
                            case .lightningInvoice(let amount):
                                viewModel.exchanger?.amount.string = amount
                                
                                navigation.push(.sendSetAmount(viewModel: viewModel))
                                navigation.push(.sendReviewTxView(viewModel: viewModel))
                            }
                        } catch {
                            withAnimation {
                                viewModel.updateError()
                            }
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
                    guard viewModel.hasAmount(item: item) else {
                        navigation.push(.sendSetAmount(viewModel: viewModel))
                        return
                    }
                    guard !viewModel.receiverAddress.isEmpty else { return }
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
