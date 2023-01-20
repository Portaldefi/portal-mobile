//
//  ReceiveView.swift
// Portal
//
//  Created by farid on 7/22/22.
//

import SwiftUI
import PortalUI

struct ReceiveView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel: ReceiveViewModel
    
    init(viewModel: ReceiveViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    ZStack {
                        HStack {
                            PButton(config: viewModel.step == .generateQR ? .onlyIcon(Asset.caretLeftIcon) : .onlyIcon(Asset.xIcon), style: .free, size: .medium, enabled: true) {
                                switch viewModel.step {
                                case .selectAsset:
                                    presentationMode.wrappedValue.dismiss()
                                case .generateQR:
                                    viewModel.clear()
                                }
                            }
                            .frame(width: 20)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 25)
                        
                        Text("Receive")
                            .frame(width: 300, height: 62)
                            .font(.Main.fixed(.monoBold, size: 16))
                    }
                    .animation(nil, value: false)
                    
                    switch viewModel.step {
                    case .selectAsset:
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Asset")
                                .font(.Main.fixed(.bold, size: 24))
                                .foregroundColor(Palette.grayScaleCA)
                            
                            ScrollView {
                                VStack {
                                    VStack(spacing: 0) {
                                        Divider()
                                        ForEach(viewModel.walletItems) { item in
                                            ZStack(alignment: .trailing) {
                                                WalletItemView(viewModel: item.viewModel, showBalance: false)
                                                    .padding(.leading)
                                                    .padding(.trailing, 6)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        viewModel.selectedItem = item
                                                    }
                                                Asset.chevronRightIcon
                                                    .foregroundColor(Palette.grayScale4A)
                                            }
                                            
                                            Divider()
                                                .overlay(Palette.grayScale2A)
                                        }
                                    }
                                }
                            }
                            .frame(height: CGFloat(viewModel.walletItems.count) * 72)
                        }
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    case .generateQR:
                        ScrollView {
                            HStack {
                                if let coin = viewModel.selectedItem?.viewModel.coin {
                                    VStack(alignment: .leading, spacing: 0) {
                                        HStack(spacing: 8) {
                                            CoinImageView(
                                                size: 24,
                                                url: coin.icon,
                                                placeholderForegroundColor: Color.gray
                                            )
                                            Text(coin.name)
                                                .font(.Main.fixed(.monoBold, size: 22))
                                                .foregroundColor(Palette.grayScaleF4)
                                        }
                                        HStack {
                                            Text("on")
                                                .font(.Main.fixed(.monoMedium, size: 16))
                                                .foregroundColor(Palette.grayScale8A)
                                            HStack(spacing: 4) {
                                                Asset.chainIcon
                                                Text("Chain")
                                                    .font(.Main.fixed(.monoMedium, size: 16))
                                                    .foregroundColor(Palette.grayScale8A)
                                            }
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                if let coin = viewModel.selectedItem?.viewModel.coin, coin.type == .bitcoin {
                                    VStack {
                                        Text("Address type")
                                            .font(.Main.fixed(.monoRegular, size: 14))
                                            .foregroundColor(Palette.grayScale6A)
                                        Text("Segwit")
                                            .font(.Main.fixed(.monoBold, size: 16))
                                            .foregroundColor(Palette.grayScaleCA)
                                    }
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.bottom, 16)
                            
                            if let qr = viewModel.qrCode {
                                ZStack {
                                    Image(uiImage: qr)
                                        .interpolation(.none)
                                        .resizable()
                                        .cornerRadius(12)
                                    
                                    Asset.portalQrIcon
                                        .resizable()
                                        .frame(width: 72, height: 72)
                                }
                                .frame(width: geo.size.width - 80)
                                .frame(height: geo.size.width - 80)
                            } else {
                                ProgressView().progressViewStyle(.circular)
                            }
                            
                            VStack(spacing: 10) {
                                Text(viewModel.receiveAddress)
                                    .font(.Main.fixed(.monoRegular, size: 14))
                                
                                HStack(spacing: 10) {
                                    PButton(config: .labelAndIconLeft(label: "Copy", icon: Asset.copyIcon), style: .outline, size: .medium, color: Palette.grayScaleEA, enabled: true) {
                                        viewModel.copyToClipboard()
                                    }
                                    
                                    PButton(config: .labelAndIconLeft(label: "Share", icon: Asset.arrowUprightIcon), style: .outline, size: .medium, color: Palette.grayScaleEA, enabled: true) {
                                        viewModel.share()
                                    }
                                }
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 16)
                            
                            VStack(spacing: 0) {
                                Divider()
                                if let exchanger = viewModel.exchanger {
                                    AmountView(exchanger: exchanger)
                                }
                                Divider()
                                DescriptionView()
                                Divider()
                            }
                            .padding(.horizontal, 24)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                
                if viewModel.editingAmount, let exchanger = viewModel.exchanger {
                    AmountEditorView(title: "Add Amount", exchanger: exchanger) {
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
                } else if viewModel.editingDescription {
                    TextEditorView(
                        title: "Description",
                        placeholder: "Write a payment description",
                        initialText: viewModel.description,
                        onCancelAction: {
                            withAnimation {
                                viewModel.editingDescription.toggle()
                            }
                        }, onSaveAction: { description in
                            withAnimation {
                                viewModel.description = description
                                viewModel.editingDescription.toggle()
                            }
                        }
                    )
                    .cornerRadius(8)
                    .offset(y: 5)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                }
            }
        }
        .navigationBarHidden(true)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .sheet(item: $viewModel.sharedAddress) { address in
            ActivityShareView(text: address.text)
        }
    }
    
    private func AmountView(exchanger: Exchanger) -> some View {
        Group {
            if exchanger.baseAmountDecimal == 0 {
                Button {
                    withAnimation {
                        viewModel.editingAmount.toggle()
                    }
                } label: {
                    HStack {
                        PButton(config: .labelAndIconLeft(label: "Add Amount", icon: Asset.pencilIcon), style: .free, size: .small, applyGradient: true, enabled: true) {
                            withAnimation {
                                viewModel.editingAmount.toggle()
                            }
                        }
                        .frame(width: 125)
                        
                        Spacer()
                    }
                    .frame(height: 62)
                    .padding(.horizontal, 24)
                }
            } else {
                Button {
                    withAnimation {
                        viewModel.editingAmount.toggle()
                    }
                } label: {
                    AmountValueView(exchanger: exchanger)
                }
            }
        }
    }
    
    private func DescriptionView() -> some View {
        Group {
            if viewModel.description.isEmpty {
                Button {
                    withAnimation {
                        viewModel.editingDescription.toggle()
                    }
                } label: {
                    HStack {
                        PButton(config: .labelAndIconLeft(label: "Add Description", icon: Asset.pencilIcon), style: .free, size: .small, applyGradient: true, enabled: true) {
                            withAnimation {
                                viewModel.editingDescription.toggle()
                            }
                        }
                        .frame(width: 170)
                        
                        Spacer()
                    }
                    .frame(height: 62)
                    .padding(.horizontal, 24)
                }
            } else {
                Button {
                    withAnimation {
                        viewModel.editingDescription.toggle()
                    }
                } label: {
                    EditableTextFieldView(description: "Description", text: viewModel.description)
                }
            }
        }
    }
}

struct ReceiveView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiveView(viewModel: ReceiveViewModel.mocked)
    }
}
