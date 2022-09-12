//
//  SendView.swift
//  BDKDemoApp
//
//  Created by farid on 26/8/22.
//

import SwiftUI
import PortalUI
import Factory

struct SendView: View {
    @FocusState private var isFocused: Bool
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var viewModel = Container.sendViewModel()
    @Injected(Container.viewState) private var viewState
    
    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 10/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .frame(width: 20)
                        
                        Spacer()
                        
                        if !viewState.showScanner {
                            PButton(config: .onlyIcon(Asset.qrIcon), style: .free, size: .medium, enabled: true) {
                                viewModel.qrScannerOpened.toggle()
                            }
                            .frame(width: 25, height: 25)
                        }
                    }
                    
                    Text("Send")
                        .font(.Main.fixed(.bold, size: 16))
                        .frame(height: 62)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let item = viewModel.selectedItem {
                            Text("From")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                            
                            WalletItemView(item: item)
                                .padding(.horizontal)
                                .contentShape(Rectangle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 42/255, green: 42/255, blue: 42/255), lineWidth: 1)
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Amount")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                            Spacer()
                            PButton(
                                config: .onlyLabel("Max"),
                                style: .free,
                                size: .small,
                                color: Color(red: 116/255, green: 138/255, blue: 254/255, opacity: 1),
                                enabled: false
                            ) {
                                
                            }
                            .frame(width: 40)
                        }
                        
                        TextField("Required", text: $viewModel.amount)
                            .focused($isFocused)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.decimalPad)
                            .font(Font.system(size: 16, weight: .bold, design: .monospaced))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        Color(red: 26/255, green: 26/255, blue: 26/255)
                                    )
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Address")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                            Spacer()
                        }
                        
                        ZStack {
                            HStack {
                                TextField("Required", text: $viewModel.to)
                                    .focused($isFocused)
                                    .disableAutocorrection(true)
                                    .textInputAutocapitalization(.never)
                                    .font(Font.system(size: 16, weight: .bold, design: .monospaced))
                            }
                            .padding()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    Color(red: 26/255, green: 26/255, blue: 26/255)
                                )
                        )
                        
                        HStack {
                            PButton(config: .labelAndIconLeft(label: "Annotate", icon: Asset.pencilIcon), style: .free, size: .small, enabled: false) {
                                
                            }
                            PButton(config: .labelAndIconLeft(label: "Tag", icon: Asset.tagIcon), style: .free, size: .small, enabled: false) {
                                
                            }
                        }
                        .padding()
                    }
                    
                    Button {
                        viewModel.goToReview.toggle()
                    } label: {
                        Text("Continue")
                            .foregroundColor(.black)
                            .font(.system(size: 22, design: .monospaced))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.blue)
                            .background(in: RoundedRectangle(cornerRadius: 10))
                            .frame(height: 60)
                    }
                    .disabled(!viewModel.sendButtonEnabled)
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused = false
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            NavigationLink(
                destination: ReviewTransactionView(),
                isActive: $viewModel.goToReview
            ) {
                EmptyView()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.qrScannerOpened, onDismiss: {
            
        }) {
            QRCodeReaderView(config: .send) { item in
                viewModel.qrCodeItem = item

                switch item.type {
                case .bip21(let address, let amount, _):
                    viewModel.to = address
                    guard let _amount = amount else { return }
                    viewModel.amount = _amount
                default:
                    break
                }
            }
        }
    }
}

struct SendView_Previews: PreviewProvider {
    static var previews: some View {
        SendView()
    }
}
