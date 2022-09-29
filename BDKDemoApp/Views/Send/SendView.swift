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
    @ObservedObject var viewModel: SendViewViewModel = Container.sendViewModel()
    @ObservedObject private var viewState = Container.viewState()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    ZStack {
                        if viewModel.step != .signing && viewModel.step != .sent  {
                            HStack {
                                PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                                    withAnimation {
                                        if viewModel.goBack() {
                                            presentationMode.wrappedValue.dismiss()
                                        }
                                    }
                                }
                                .frame(width: 20)
                                
                                Spacer()
                            }
                        }
                        
                        Text(viewModel.title)
                            .frame(width: 300, height: 62)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .animation(nil)
                    }
                    
                    switch viewModel.step {
                    case .recipient:
                        SetRecipientView(viewModel: viewModel)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    case .amount:
                        SetAmountView(viewModel: viewModel)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    case .review, .signing, .sent:
                        ReviewTransactionView()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            
            if viewState.showFeesPicker {
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        Divider()
                            .frame(height: 1)
                            .overlay(Palette.grayScale4A)
                        
                        HStack {
                            Text("Change Fee")
                                .font(.Main.fixed(.monoBold, size: 16))
                                .foregroundColor(Palette.grayScaleF4)
                        }
                        .frame(height: 62)

                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    Palette.grayScale20
                                )
                            VStack(alignment: .leading, spacing: 0) {
                                Button {
                                    withAnimation {
                                        viewModel.feesPickerSelection = 1
                                    }
                                } label: {
                                    HStack {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Palette.grayScale2A, lineWidth: 2)
                                                    .frame(width: 24, height: 24)
                                                if viewModel.feesPickerSelection == 1 {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(
                                                            RadialGradient.main
                                                        )
                                                        .frame(width: 22, height: 22)
                                                }
                                            }

                                            Text("Fast")
                                                .font(.Main.fixed(.monoBold, size: 16))
                                                .foregroundColor(Palette.grayScaleF4)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("~10 mins")
                                                .font(.Main.fixed(.monoRegular, size: 16))
                                                .foregroundColor(Palette.grayScaleF4)
                                            Text("4 sat/vByte")
                                                .font(.Main.fixed(.monoRegular, size: 14))
                                                .foregroundColor(Palette.grayScale8A)
                                        }
                                    }
                                    .frame(height: 72)
                                    .padding(.horizontal, 16)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                Divider()
                                
                                Button {
                                    withAnimation {
                                        viewModel.feesPickerSelection = 2
                                    }
                                } label: {
                                    HStack {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Palette.grayScale2A, lineWidth: 2)
                                                    .frame(width: 24, height: 24)
                                                if viewModel.feesPickerSelection == 2 {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(
                                                            RadialGradient.main
                                                        )
                                                        .frame(width: 22, height: 22)
                                                }
                                            }
                                            
                                            Text("Normal")
                                                .font(.Main.fixed(.monoBold, size: 16))
                                                .foregroundColor(Palette.grayScaleF4)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("~3 hrs")
                                                .font(.Main.fixed(.monoRegular, size: 16))
                                                .foregroundColor(Palette.grayScaleF4)
                                            Text("2 sat/vByte")
                                                .font(.Main.fixed(.monoRegular, size: 14))
                                                .foregroundColor(Palette.grayScale8A)
                                        }
                                    }
                                    .frame(height: 72)
                                    .padding(.horizontal, 16)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                Divider()
                                
                                Button {
                                    withAnimation {
                                        viewModel.feesPickerSelection = 3
                                    }
                                } label: {
                                    HStack {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Palette.grayScale2A, lineWidth: 2)
                                                    .frame(width: 24, height: 24)
                                                if viewModel.feesPickerSelection == 3 {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(
                                                            RadialGradient.main
                                                        )
                                                        .frame(width: 22, height: 22)
                                                }
                                            }
                                            
                                            Text("Slow")
                                                .font(.Main.fixed(.monoBold, size: 16))
                                                .foregroundColor(Palette.grayScaleF4)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("~1 day")
                                                .font(.Main.fixed(.monoRegular, size: 16))
                                                .foregroundColor(Palette.grayScaleF4)
                                            Text("1 sat/vByte")
                                                .font(.Main.fixed(.monoRegular, size: 14))
                                                .foregroundColor(Palette.grayScale8A)
                                        }
                                    }
                                    .frame(height: 72)
                                    .padding(.horizontal, 16)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                
                                Divider()
                                
                                Button {
                                    withAnimation {
                                        viewModel.feesPickerSelection = 4
                                    }
                                } label: {
                                    HStack {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Palette.grayScale2A, lineWidth: 2)
                                                    .frame(width: 24, height: 24)
                                                if viewModel.feesPickerSelection == 4 {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(
                                                            RadialGradient.main
                                                        )
                                                        .frame(width: 22, height: 22)
                                                }
                                            }
                                            
                                            Text("Custom")
                                                .font(.Main.fixed(.monoBold, size: 16))
                                                .foregroundColor(Palette.grayScaleF4)
                                        }
                                        
                                        Spacer()
                                        
                                        Asset.chevronRightIcon
                                            .foregroundColor(Palette.grayScale4A)
                                    }
                                    .frame(height: 72)
                                    .padding(.horizontal, 16)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 299)
                    }
                    .background(
                        Palette.grayScale2A.edgesIgnoringSafeArea(.bottom)
                    )
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                
            } else {
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
                        } else if !viewModel.exchanger.amountIsValid {
                            Text("Invalid Amount")
                                .font(.Main.fixed(.monoRegular, size: 16))
                                .foregroundColor(Color(red: 255/255, green: 82/255, blue: 82/255))
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        HStack {
                            switch viewModel.step {
                            case .recipient, .amount, .review:
                                PButton(config: .onlyLabel(viewModel.actionButtonTitle), style: .filled, size: .big, enabled: viewModel.actionButtonEnabled) {
                                    withAnimation {
                                        viewModel.onActionButtonPressed()
                                    }
                                }
                            case .signing:
                                HStack(spacing: 16) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Text("Signing transaction...")
                                        .font(.Main.fixed(.monoBold, size: 16))
                                        .foregroundColor(Palette.grayScaleF4)
                                }
                                .frame(height: 60)
                            case .sent:
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .resizable()
                                        .frame(width: 28, height: 28)
                                        .foregroundColor(Color.green)
                                    Text("Signed!")
                                        .font(.Main.fixed(.monoBold, size: 16))
                                        .foregroundColor(Palette.grayScaleF4)
                                }
                                .frame(height: 60)
                            }
                        }
                        
                    }
                    .padding(16)
                }
                .background(
                    Palette.grayScale2A.edgesIgnoringSafeArea(.bottom)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.qrScannerOpened, onDismiss: {
            viewModel.qrScannerOpened = false
        }) {
            QRCodeReaderView(config: .send) { item in
                viewModel.qrCodeItem = item
                
                switch item.type {
                case .bip21(let address, let amount, _):
                    viewModel.to = address
                    guard let _amount = amount else { return }
                    viewModel.exchanger.cryptoAmount = _amount
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
