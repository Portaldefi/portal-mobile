//
//  SetAmountView.swift
// Portal
//
//  Created by farid on 9/12/22.
//

import SwiftUI
import PortalUI
import Factory
import PopupView

struct SetAmountView: View {
    private let warningColor = Color(red: 1, green: 0.321, blue: 0.321)
    @ObservedObject private var viewState: ViewState = Container.viewState()
    @EnvironmentObject private var navigation: NavigationStack
    @Environment(SendViewViewModel.self) var viewModel: SendViewViewModel
    @FocusState private var focusedField: Bool
    
//    init(viewModel: SendViewViewModel) {
//        self.viewModel = viewModel
//    }
    
    var body: some View {
        @Bindable var bindableViewModel = viewModel

        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                            viewModel.clearAmount()
                            navigation.pop()
                        }
                        .frame(width: 20)
                        
                        Spacer()
                    }
                    
                    Text("Send")
                        .frame(width: 300, height: 62)
                        .font(.Main.fixed(.monoBold, size: 16))
                }
                
                if !viewState.isReachable {
                    NoInternetConnectionView()
                        .padding(.horizontal, -16)
                        .padding(.bottom, 8)
                }
                
                if let exchanger = viewModel.exchanger {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Set Amount")
                                .font(.Main.fixed(.bold, size: 24))
                                .foregroundColor(Palette.grayScaleCA)
                            Spacer()
                            
                            Button {
                                viewModel.useAllFunds()
                            } label: {
                                RadialGradient.main
                                    .mask {
                                        Text("Use all funds")
                                            .font(.Main.fixed(.monoBold, size: 16))
                                    }
                            }
                            .buttonStyle(.plain)
                            .frame(width: 125, height: 33)
                            .disabled(!viewModel.useAllFundsEnabled)
                        }
                        
                        AmountView(exchanger: exchanger, isValid: viewModel.amountIsValid)
                            .focused($focusedField)
                    }
                    
                    HStack(alignment: .top) {
                        Text("Asset Balance")
                            .font(.Main.fixed(.monoBold, size: 14))
                            .foregroundColor(Palette.grayScaleAA)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            switch exchanger.side {
                            case .base:
                                HStack(spacing: 0) {
                                    Text(viewModel.balanceString)
                                        .font(.Main.fixed(.monoMedium, size: 16))
                                        .if(exchanger.side == .base, then: { text in
                                            text.foregroundColor(viewModel.amountIsValid ?  Palette.grayScaleCA : warningColor)
                                        }, else: { text in
                                            text.foregroundColor(Palette.grayScaleCA)
                                        })
                                            
                                    Text(exchanger.base.code.lowercased())
                                        .font(.Main.fixed(.monoMedium, size: 11))
                                        .foregroundColor(Palette.grayScale6A)
                                        .frame(width: 34)
                                        .offset(y: 2)
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                
                                HStack(spacing: 0) {
                                    Text(viewModel.valueString)
                                        .font(.Main.fixed(.monoMedium, size: 16))
                                        .if(exchanger.side == .quote, then: { text in
                                            text.foregroundColor(viewModel.amountIsValid ?  Palette.grayScaleCA : warningColor)
                                        }, else: { text in
                                            text.foregroundColor(Palette.grayScale6A)
                                        })
                                            
                                        Text(viewModel.fiatCurrency.code.lowercased())
                                            .font(.Main.fixed(.monoMedium, size: 11))
                                            .foregroundColor(Palette.grayScale6A)
                                            .frame(width: 34)
                                            .offset(y: 2)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                                
                            case .quote:
                                HStack(spacing: 0) {
                                    Text(viewModel.valueString)
                                        .font(.Main.fixed(.monoMedium, size: 16))
                                        .if(exchanger.side == .quote, then: { text in
                                            text.foregroundColor(viewModel.amountIsValid ?  Palette.grayScaleCA : warningColor)
                                        }, else: { text in
                                            text.foregroundColor(Palette.grayScaleCA)
                                        })
                                            
                                    Text(viewModel.fiatCurrency.code.lowercased())
                                        .font(.Main.fixed(.monoMedium, size: 11))
                                        .foregroundColor(Palette.grayScale6A)
                                        .frame(width: 34)
                                        .offset(y: 2)
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                
                                HStack(spacing: 0) {
                                    Text(viewModel.balanceString)
                                        .font(.Main.fixed(.monoMedium, size: 16))
                                        .if(exchanger.side == .base, then: { text in
                                            text.foregroundColor(viewModel.amountIsValid ?  Palette.grayScaleCA : warningColor)
                                        }, else: { text in
                                            text.foregroundColor(Palette.grayScale6A)
                                        })
                                            
                                    Text(exchanger.base.code.lowercased())
                                        .font(.Main.fixed(.monoMedium, size: 11))
                                        .foregroundColor(Palette.grayScale6A)
                                        .frame(width: 34)
                                        .offset(y: 2)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                                
                            }
                        }
                    }
                    .frame(height: 72)
                    
                    if viewModel.showFees {
                        Divider()
                        
                        HStack(spacing: 0) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Fees")
                                    .font(.Main.fixed(.monoBold, size: 14))
                                    .foregroundColor(Palette.grayScaleAA)
                                Text(viewModel.feeRate.description)
                                    .font(.Main.fixed(.monoRegular, size: 14))
                                    .foregroundColor(Color(red: 0.191, green: 0.858, blue: 0.418))
                            }
                            
                            Spacer()
                            
                            if let coin = viewModel.coin, viewModel.recomendedFees != nil {
                                VStack {
                                    HStack(spacing: 8) {
                                        Text(viewModel.fee)
                                            .font(.Main.fixed(.monoBold, size: 16))
                                            .foregroundColor(Palette.grayScaleEA)
                                        
                                        switch coin.type {
                                        case .bitcoin, .lightningBitcoin:
                                            Text("btc")
                                                .font(.Main.fixed(.monoMedium, size: 11))
                                                .foregroundColor(Palette.grayScale6A)
                                                .frame(width: 20)
                                            
                                        case .ethereum, .erc20:
                                            Text("eth")
                                                .font(.Main.fixed(.monoMedium, size: 11))
                                                .foregroundColor(Palette.grayScale6A)
                                                .frame(width: 20)
                                        }
                                    }
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            } else {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            
                            if let coin = viewModel.coin, coin == .bitcoin() {
                                Asset.chevronRightIcon
                                    .foregroundColor(Palette.grayScale4A)
                            }
                        }
                        .frame(height: 72)
                        .transition(.opacity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard let coin = viewModel.coin, coin == .bitcoin() else { return }
                            focusedField = false
                            viewModel.showFeesPicker.toggle()
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            if focusedField {
                VStack(spacing: 0) {
                    Divider()
                        .frame(height: 1)
                        .overlay(Palette.grayScale4A)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        if !viewModel.amountIsValid {
                            Text("Not enough funds")
                                .font(.Main.fixed(.monoRegular, size: 16))
                                .foregroundColor(Color(red: 255/255, green: 82/255, blue: 82/255))
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        if let exchanger = viewModel.exchanger {
                            PButton(
                                config: .onlyLabel("Continue"),
                                style: .filled,
                                size: .big,
                                enabled: viewModel.amountIsValid && exchanger.baseAmountDecimal > 0 && viewState.isReachable
                            ) {
                                navigation.push(.sendReviewTxView(viewModel: viewModel))
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
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .popup(isPresented: $bindableViewModel.showFeesPicker) {
            if let fees = viewModel.recomendedFees, let coin = viewModel.coin {
                TxFeesPickerView(
                    coin: coin,
                    recommendedFees: fees,
                    feeRate: $bindableViewModel.feeRate,
                    onDismiss: {
                        focusedField = true
                        viewModel.showFeesPicker.toggle()
                    }
                )
            } else {
                EmptyView()
            }
        } customize: {
            $0.type(.toast)
              .position(.bottom)
              .animation(.spring())
              .closeOnTap(false)
              .closeOnTapOutside(true)
              .backgroundColor(.black.opacity(0.5))
              .dismissCallback {
                  focusedField = true
              }
        }
        .onAppear {
            focusedField = true
        }
    }
}

struct SetAmountView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.walletManager.register { WalletManager.mocked }
        let _ = Container.adapterManager.register { AdapterManager.mocked }
        let _ = Container.viewState.register { ViewState.mocked(hasConnection: true) }
        
        SetAmountView().environment(SendViewViewModel.mocked)
    }
}

struct SetAmountView_No_Connection: PreviewProvider {
    static var previews: some View {
        let _ = Container.walletManager.register { WalletManager.mocked }
        let _ = Container.adapterManager.register { AdapterManager.mocked }
        let _ = Container.viewState.register { ViewState.mocked(hasConnection: false) }
        
        SetAmountView().environment(SendViewViewModel.mocked)
    }
}

