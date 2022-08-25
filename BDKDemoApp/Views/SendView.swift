//
//  SendView.swift
//  BDKDemoApp
//
//  Created by farid on 7/25/22.
//

import SwiftUI
import Combine
import PortalUI

struct SendView: View {
    @Binding var item: QRCodeItem?
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel = SendViewViewModel()
    @FocusState private var isFocused: Bool
        
    init(qrItem: Binding<QRCodeItem?>) {
        UITableView.appearance().backgroundColor = .clear
        self._item = qrItem
    }
    
    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 10/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack {
                    if viewModel.selectedItem != nil {
                        HStack {
                            PButton(config: .onlyIcon(Asset.arrowLeftIcon), style: .free, size: .big, enabled: viewModel.selectedItem != nil) {
                                withAnimation {
                                    viewModel.selectedItem = nil
                                }
                            }
                            .frame(width: 20)
                            
                            Spacer()
                        }
                    }
                    
                    Text("Send")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .frame(height: 62)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                        
                        ScrollView {
                            VStack {
                                if let item = viewModel.selectedItem {
                                    WalletItemView(item: item)
                                        .padding(.horizontal)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(red: 42/255, green: 42/255, blue: 42/255), lineWidth: 1)
                                        )
                                        .contentShape(Rectangle())
                                } else {
                                    ForEach(viewModel.walletItems) { item in
                                        WalletItemView(item: item)
                                            .padding(.horizontal)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(red: 42/255, green: 42/255, blue: 42/255), lineWidth: 1)
                                            )
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                withAnimation {
                                                    viewModel.selectedItem = item
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        .frame(height: CGFloat(viewModel.walletItems.count) * 66)
                    }
                    
                    if viewModel.selectedItem != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Amount")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                Spacer()
                                PButton(config: .onlyLabel("Max"), style: .free, size: .small, enabled: false) {
                                    
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
                                PButton(config: .onlyLabel("Select from Contacts"), style: .free, size: .small, enabled: false) {
                                    
                                }
                                .frame(width: 200)
                            }
                            
                            ZStack {
                                HStack {
                                    TextField("Required", text: $viewModel.to)
                                        .focused($isFocused)
                                        .disableAutocorrection(true)
                                        .textInputAutocapitalization(.never)
                                        .font(Font.system(size: 16, weight: .bold, design: .monospaced))
                                    
                                    PButton(config: .onlyIcon(Asset.qrIcon), style: .free, size: .big, enabled: true) {
                                        viewModel.qrScannerOpened.toggle()
                                    }
                                    .frame(width: 25, height: 25)
                                    .border(Color.blue)
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
                    }
                }
                
                if viewModel.selectedItem != nil {
                    Button {
                        viewModel.send()
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
                Spacer()
            }
            .modifier(BackButtonModifier())
            .padding(.horizontal, 16)
        }
        .onTapGesture {
            isFocused = false
        }
        .navigationTitle("Send Bitcoin")
        .onAppear {
            print(item)
            viewModel.set(item: item)
        }
        .alert(isPresented: $viewModel.showSuccessAlet) {
            Alert(title: Text("\(viewModel.amount) sat sent!"),
                  message: Text("to: \(viewModel.to)"),
                  dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(title: Text("Send error"),
                  message: Text("\(viewModel.sendError.debugDescription)"),
                  dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $viewModel.qrScannerOpened, onDismiss: {
            
        }) {
            QRCodeScannerView { item in
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
        SendView(qrItem: .constant(nil))
            .environmentObject(AccountViewModel.mocked())
    }
}
