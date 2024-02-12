//
//  CreateChannelView.swift
//  Portal
//
//  Created by farid on 20.12.2023.
//

import SwiftUI
import Factory
import PortalUI

struct CreateChannelView: View {
    private let warningColor = Color(red: 1, green: 0.321, blue: 0.321)
    
    @FocusState private var focusedField: Bool
    
    @State private var viewModel: CreateChannelViewModel
    @State private var channelIsOpening = false
    @State private var errorMessage: String?
    
    @Injected(Container.viewState) private var viewState
    @Environment(NavigationStack.self) private var navigation: NavigationStack
    
    init(peer: Peer) {
        self._viewModel = State(initialValue: CreateChannelViewModel(peer: peer))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                            viewModel.disconnetPeer()
                            navigation.pop()
                        }
                        .frame(width: 20)
                        
                        Spacer()
                    }
                    
                    Text("Create a channel")
                        .frame(width: 300, height: 62)
                        .font(.Main.fixed(.monoBold, size: 16))
                }
                
                if !viewState.isReachable {
                    NoInternetConnectionView()
                        .padding(.horizontal, -16)
                }
                
                if let exchanger = viewModel.exchanger {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Fund Channel")
                                .font(.Main.fixed(.bold, size: 24))
                                .foregroundColor(Palette.grayScaleCA)
                            Spacer()
                            
                            //                            Button {
                            //                                viewModel.useAllFunds()
                            //                            } label: {
                            //                                RadialGradient.main
                            //                                    .mask {
                            //                                        Text("Use all funds")
                            //                                            .font(.Main.fixed(.monoBold, size: 16))
                            //                                    }
                            //                            }
                            //                            .buttonStyle(.plain)
                            //                            .frame(width: 125, height: 33)
                            //                            .disabled(!viewModel.useAllFundsEnabled)
                        }
                        
                        AmountView(exchanger: exchanger, isValid: viewModel.amountIsValid)
                            .focused($focusedField)
                    }
                    
                    HStack(alignment: .top) {
                        Text("On-chain Balance")
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
                            
                            if viewModel.recomendedFees != nil {
                                VStack {
                                    HStack(spacing: 8) {
                                        Text(viewModel.fee)
                                            .font(.Main.fixed(.monoBold, size: 16))
                                            .foregroundColor(Palette.grayScaleEA)
                                        
                                        Text("btc")
                                            .font(.Main.fixed(.monoMedium, size: 11))
                                            .foregroundColor(Palette.grayScale6A)
                                            .frame(width: 20)
                                    }
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            } else {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            
                            Asset.chevronRightIcon
                                .foregroundColor(Palette.grayScale4A)
                        }
                        .frame(height: 72)
                        .transition(.opacity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedField = false
                            viewModel.showFeesPicker.toggle()
                        }
                    }
                }
                
                
                
                Spacer()
            }
            .padding(.horizontal, 18)
            
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
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(.Main.fixed(.monoRegular, size: 16))
                            .foregroundColor(Color(red: 255/255, green: 82/255, blue: 82/255))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    if let exchanger = viewModel.exchanger {
                        PButton(
                            config: .onlyLabel(errorMessage == nil ? "Fund Channel" : "Try Again"),
                            style: .filled,
                            size: .big,
                            enabled: viewModel.amountIsValid && exchanger.baseAmountDecimal > 0 && viewState.isReachable
                        ) {
                            Task {
                                do {
                                    errorMessage = nil
                                    channelIsOpening.toggle()
                                    try await viewModel.openChannel()
                                    navigation.push(.awaitsFundingChannelView(peer: viewModel.peer))
                                    channelIsOpening.toggle()
                                } catch {
                                    channelIsOpening.toggle()
                                    errorMessage = "\(error)"
                                    print("Open channel error: \(error)")
                                }
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
        .disabled(channelIsOpening)
        .opacity(channelIsOpening ? 0.65 : 1)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
    }
}

#Preview {
    CreateChannelView(peer: .alice)
}
