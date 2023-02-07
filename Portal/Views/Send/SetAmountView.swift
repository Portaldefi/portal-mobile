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
    @EnvironmentObject private var navigation: NavigationStack
    @ObservedObject private var viewModel: SendViewViewModel
    @State private var showFeesPicker = false
    
    init(viewModel: SendViewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
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
                            withAnimation {
                                showFeesPicker.toggle()
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)

            if showFeesPicker, let fees = viewModel.recomendedFees, let coin = viewModel.coin {
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
                                        showFeesPicker = false
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
                                        showFeesPicker = false
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
                                        showFeesPicker = false
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
                                        showFeesPicker = false
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
                                            Text(fees.hourFee.double.formattedString(.coin(.bitcoin()), decimals: 8) + "\(coin.type == .bitcoin ? " sat/vByte" : " eth")")
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

            }
                        
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
                        PButton(config: .onlyLabel("Continue"), style: .filled, size: .big, enabled: viewModel.amountIsValid && exchanger.baseAmountDecimal > 0) {
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
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
    }
}

struct SetAmountView_Previews: PreviewProvider {
    static var previews: some View {
        SetAmountView(viewModel: SendViewViewModel.mocked)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
