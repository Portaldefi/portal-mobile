//
//  SendView.swift
// Portal
//
//  Created by farid on 26/8/22.
//

import SwiftUI
import PortalUI
import Factory

struct SendView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: SendViewViewModel = Container.sendViewModel()
    @ObservedObject private var viewState = Container.viewState()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    ZStack {
                        if viewModel.step != .signing && viewModel.step != .sent  {
                            HStack {
                                PButton(config: viewModel.step == .selectAsset ? .onlyIcon(Asset.xIcon): .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
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
                    }
                    .animation(nil, value: false)
                    
                    switch viewModel.step {
                    case .recipient:
                        SetRecipientView(viewModel: viewModel)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    case .amount:
                        SetAmountView(viewModel: viewModel)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    case .review, .signing, .sent:
                        ReviewTransactionView(viewModel: viewModel)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    case .selectAsset:
                        SelectAssetView(viewModel: viewModel)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            
            if viewState.showFeesPicker, let fees = viewModel.recomendedFees, let coin = viewModel.selectedItem?.viewModel.coin {
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        Divider()
                            .frame(height: 1)
                            .overlay(Palette.grayScale4A)
                        
                        ZStack {
                            Text("Change Fee")
                                .font(.Main.fixed(.monoBold, size: 16))
                                .foregroundColor(Palette.grayScaleF4)
                            
                            HStack {
                                PButton(config: .onlyLabel("Cancel"), style: .free, size: .small, applyGradient: true, enabled: true) {
                                    withAnimation {
                                        viewModel.viewState.showFeesPicker = false
                                    }
                                }
                                .frame(width: 58)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
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
                                        viewModel.feeRate = .fast
                                        viewModel.viewState.showFeesPicker = false
                                    }
                                } label: {
                                    HStack {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Palette.grayScale2A, lineWidth: 2)
                                                    .frame(width: 24, height: 24)
                                                
                                                RoundedRectangle(cornerRadius: 12)
                                                    .foregroundColor(Palette.grayScale10)
                                                    .frame(width: 22, height: 22)
                                                
                                                if viewModel.feeRate == .fast {
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
                                            Text(fees.fastestFee.double.formattedString(.coin(coin), decimals: 8) + "\(coin.type == .bitcoin ? " sat/vByte" : " eth")")
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
                                        viewModel.feeRate = .normal
                                        viewModel.viewState.showFeesPicker = false
                                    }
                                } label: {
                                    HStack {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Palette.grayScale2A, lineWidth: 2)
                                                    .frame(width: 24, height: 24)
                                                
                                                RoundedRectangle(cornerRadius: 12)
                                                    .foregroundColor(Palette.grayScale10)
                                                    .frame(width: 22, height: 22)
                                                
                                                if viewModel.feeRate == .normal {
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
                                            Text("~30 mins")
                                                .font(.Main.fixed(.monoRegular, size: 16))
                                                .foregroundColor(Palette.grayScaleF4)
                                            Text(fees.halfHourFee.double.formattedString(.coin(coin), decimals: 8) + "\(coin.type == .bitcoin ? " sat/vByte" : " eth")")
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
                                        viewModel.feeRate = .slow
                                        viewModel.viewState.showFeesPicker = false
                                    }
                                } label: {
                                    HStack {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Palette.grayScale2A, lineWidth: 2)
                                                    .frame(width: 24, height: 24)
                                                
                                                RoundedRectangle(cornerRadius: 12)
                                                    .foregroundColor(Palette.grayScale10)
                                                    .frame(width: 22, height: 22)
                                                
                                                if viewModel.feeRate == .slow {
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
                                            Text("~60 mins")
                                                .font(.Main.fixed(.monoRegular, size: 16))
                                                .foregroundColor(Palette.grayScaleF4)
                                            Text(fees.hourFee.double.formattedString(.coin(.bitcoin()), decimals: 8) + "\(viewModel.selectedItem!.viewModel.coin.type == .bitcoin ? " sat/vByte" : " eth")")
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
//                                    withAnimation {
//                                        viewModel.fee = .custom
//                                    }
                                } label: {
                                    HStack {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Palette.grayScale2A, lineWidth: 2)
                                                    .frame(width: 24, height: 24)
                                                
                                                RoundedRectangle(cornerRadius: 12)
                                                    .foregroundColor(Palette.grayScale10)
                                                    .frame(width: 22, height: 22)
                                                
                                                if viewModel.feeRate == .custom {
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
                
            } else if viewModel.editingAmount {
                AmountEditorView(title: "Edit Amount", exchanger: viewModel.exchanger!) {
                    withAnimation {
                        viewModel.editingAmount.toggle()
                    }
                } onSaveAction: { amount in
                    withAnimation {
                        viewModel.editingAmount.toggle()
                    }
                }
                .cornerRadius(8)
                .offset(y: 5)
                .transition(.move(edge: .bottom))
                .zIndex(1)
            } else {
                if viewModel.step != .selectAsset {
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
                            } else if !viewModel.amountIsValid {
                                Text("Not enough funds")
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
                                case .selectAsset:
                                    EmptyView()
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
            }
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.viewState.showInContextScanner) {
            QRCodeReaderView(config: .send(viewModel.selectedItem!.viewModel.coin)) { item in
                switch item.type {
                case .bip21(let address, let amount, _):
                    viewModel.receiverAddress = address
                    guard let _amount = amount else { return }
                    viewModel.exchanger?.amount.string = _amount
                default:
                    break
                }
            }
        }
    }
}

struct SendView_Previews: PreviewProvider {
    static var previews: some View {
        SendView(viewModel: SendViewViewModel.mocked)
    }
}
