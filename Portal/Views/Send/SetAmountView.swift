//
//  SetAmountView.swift
// Portal
//
//  Created by farid on 9/12/22.
//

import SwiftUI
import PortalUI
import Factory

struct SetAmountView: View {
    private let warningColor = Color(red: 1, green: 0.321, blue: 0.321)
    @ObservedObject private var viewModel: SendViewViewModel
    @Injected(Container.viewState) private var viewState
    
    init(viewModel: SendViewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
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
                                        
                                        Text("usd")
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
                                        
                                Text("usd")
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
                        
                        if let coin = viewModel.selectedItem?.viewModel.coin, viewModel.recomendedFees != nil {
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
                        
                        if let coin = viewModel.selectedItem?.viewModel.coin, coin == .bitcoin() {
                            Asset.chevronRightIcon
                                .foregroundColor(Palette.grayScale4A)
                        }
                    }
                    .frame(height: 72)
                    .transition(.opacity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard let coin = viewModel.selectedItem?.viewModel.coin, coin == .bitcoin() else { return }
                        withAnimation {
                            viewState.showFeesPicker.toggle()
                        }
                    }
                } else {
                    Spacer()
                        .frame(height: 72)
                }
            }
        }
    }
}

struct SetAmountView_Previews: PreviewProvider {
    static var previews: some View {
        SetAmountView(viewModel: SendViewViewModel.mocked)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
