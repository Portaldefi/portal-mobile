//
//  RestoreAccountView.swift
// Portal
//
//  Created by farid on 8/9/22.
//

import SwiftUI
import PortalUI
import Factory

struct RestoreAccountView: View {
    @FocusState private var isFocused: Bool
    @StateObject private var viewModel = RestoreAccountViewModel()
    @EnvironmentObject private var navigation: NavigationStack
    @ObservedObject private var viewState = Container.viewState()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                ZStack {
                    HStack {
                        PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                            navigation.pop()
                        }
                        .frame(width: 20)
                        
                        Spacer()
                        
                        Asset.helpIcon
                            .foregroundColor(Palette.grayScale8A)
                    }
                    
                    Text("Import")
                        .font(.Main.fixed(.monoBold, size: 16))
                }
                .frame(height: 62)
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Enter your Seed Phrase to import:")
                        .font(.Main.fixed(.monoBold, size: 16))
                    
                    ZStack(alignment: .topLeading) {
                        if viewModel.validInput {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Palette.grayScale3A, lineWidth: 1)
                                .allowsHitTesting(false)
                                .frame(height: 138)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 255/255, green: 82/255, blue: 82/255), lineWidth: 1)
                                .allowsHitTesting(false)
                                .frame(height: 138)
                        }
                        
                        TextEditor(text: $viewModel.input)
                            .textInputAutocapitalization(.never)
                            .focused($isFocused)
                            .foregroundColor(viewModel.validInput ? .white : Color(red: 1, green: 0.349, blue: 0.349))
                            .font(.Main.fixed(.monoBold, size: 16))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(height: 138)
                            .onChange(of: isFocused) { focused in
                                if focused {
                                    withAnimation {
                                        viewModel.validInput = true
                                    }
                                }
                            }
                            .onChange(of: viewModel.validInput) { valid in
                                if !valid {
                                    isFocused = false
                                }
                            }

                        if viewModel.input.isEmpty {
                            Text("Value")
                                .font(.Main.fixed(.monoRegular, size: 16))
                                .foregroundColor(Palette.grayScale4A)
                                .padding(16)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(Color.black)
                    .cornerRadius(12)
                    
                    PButton(
                        config: .labelAndIconLeft(label: "Paste", icon: Asset.pasteIcon),
                        style: .outline,
                        size: .medium,
                        enabled: true
                    ) {
                        viewModel.pasteFromClipboard()
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .if(viewModel.isDetecting, then: { view in
                view.opacity(0.3)
            }, else: { view in
                view.opacity(1)
            })
            
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                    .frame(height: 1)
                    .overlay(Palette.grayScale4A)
                
                if viewModel.isDetecting {
                    HStack(spacing: 24) {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Detecting...")
                            .font(.Main.fixed(.monoBold, size: 16))
                        Spacer()
                    }
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    if !viewModel.validInput {
                        Text("No Supported Item Detected")
                            .foregroundColor(Color(red: 1, green: 0.349, blue: 0.349))
                            .font(.Main.fixed(.monoBold, size: 16))
                            .padding([.horizontal, .top])
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    PButton(config: .onlyLabel("Continue"), style: .filled, size: .big, enabled: !viewModel.input.isEmpty && viewModel.validInput) {
                        withAnimation {
                            viewModel.validateInput()
                        }
                    }
                    .padding(16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(
                Palette.grayScale2A.edgesIgnoringSafeArea(.bottom)
            )
        }
        .onChange(of: viewModel.restorable, perform: { restorable in
            if restorable {
                navigation.push(.restoreConfirmation(viewModel: viewModel))
            }
        })
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .alert(isPresented: $viewModel.clipboardIsEmpty) {
            Alert(title: Text("Empty Clipboard"), message: Text("You don't have anything in your device clipboard."), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $viewState.showInContextScanner) {
             QRCodeReaderView(config: .importing) { item in
                switch item.type {
                case .privKey(let key):
                    viewModel.input = key
                case .pubKey(let key):
                    viewModel.input = key
                default:
                    break
                }
            }
        }
    }
}

struct RestoreAccountView_Previews: PreviewProvider {
    static var previews: some View {
        RestoreAccountView()
    }
}
