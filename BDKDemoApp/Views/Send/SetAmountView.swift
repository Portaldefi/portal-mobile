//
//  SetAmountView.swift
//  BDKDemoApp
//
//  Created by farid on 9/12/22.
//

import SwiftUI
import PortalUI

struct SetAmountView: View {
    private let warningColor = Color(red: 1, green: 0.321, blue: 0.321)
    private let assetBalance: String
    private let totalValue: String
    @ObservedObject var exchanger: Exchanger
    
    init(assetBalance: String, totalValue: String, exchanger: Exchanger) {
        self.assetBalance = assetBalance
        self.totalValue = totalValue
        self.exchanger = exchanger
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Set Amount")
                        .font(.Main.fixed(.bold, size: 24))
                        .foregroundColor(Palette.grayScaleCA)
                    Spacer()
                    PButton(
                        config: .onlyLabel("Use all funds"),
                        style: .free,
                        size: .medium,
                        color: Color(red: 116/255, green: 138/255, blue: 254/255),
                        enabled: true
                    ) {
                        
                    }
                    .frame(width: 125)
                }
                
                AmountView(exchanger: exchanger)
            }
            
            HStack(alignment: .top) {
                Text("Asset Balance")
                    .font(.Main.fixed(.bold, size: 14))
                    .foregroundColor(Palette.grayScaleAA)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    switch exchanger.side {
                    case .crypto:
                        HStack(spacing: 0) {
                            Text(assetBalance)
                                .font(.Main.fixed(.medium, size: 16))
                                .if(exchanger.side == .crypto, then: { text in
                                    text.foregroundColor(exchanger.isValid ? Palette.grayScaleCA : warningColor)
                                }, else: { text in
                                    text.foregroundColor(Palette.grayScaleCA)
                                })
                            
                            Text("btc")
                                .font(.Main.fixed(.medium, size: 11))
                                .foregroundColor(Palette.grayScale6A)
                                .frame(width: 34)
                                .offset(y: 2)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        HStack(spacing: 0) {
                            Text(totalValue)
                                .font(.Main.fixed(.medium, size: 16))
                                .if(exchanger.side == .currency, then: { text in
                                    text.foregroundColor(exchanger.isValid ? Palette.grayScale6A : warningColor)
                                }, else: { text in
                                    text.foregroundColor(Palette.grayScale6A)
                                })

                            Text("usd")
                                .font(.Main.fixed(.medium, size: 11))
                                .foregroundColor(Palette.grayScale6A)
                                .frame(width: 34)
                                .offset(y: 2)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))

                    case .currency:
                        HStack(spacing: 0) {
                            Text(totalValue)
                                .font(.Main.fixed(.medium, size: 16))
                                .if(exchanger.side == .currency, then: { text in
                                    text.foregroundColor(exchanger.isValid ? Palette.grayScaleCA : warningColor)
                                }, else: { text in
                                    text.foregroundColor(Palette.grayScaleCA)
                                })

                            Text("usd")
                                .font(.Main.fixed(.medium, size: 11))
                                .foregroundColor(Palette.grayScale6A)
                                .frame(width: 34)
                                .offset(y: 2)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        HStack(spacing: 0) {
                            Text(assetBalance)
                                .font(.Main.fixed(.medium, size: 16))
                                .if(exchanger.side == .crypto, then: { text in
                                    text.foregroundColor(exchanger.isValid ? Palette.grayScale6A : warningColor)
                                }, else: { text in
                                    text.foregroundColor(Palette.grayScale6A)
                                })
                            
                            Text("btc")
                                .font(.Main.fixed(.medium, size: 11))
                                .foregroundColor(Palette.grayScale6A)
                                .frame(width: 34)
                                .offset(y: 2)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))

                    }
                }
            }
            .frame(height: 72)
            
            if let fee = exchanger.fee, !fee.isEmpty {
                Divider()
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fees")
                            .font(.Main.fixed(.bold, size: 14))
                            .foregroundColor(Palette.grayScaleAA)
//                        if exchanger.fee != nil {
                            Text("Fast ~ 10-20 mins")
                                .font(.Main.fixed(.bold, size: 14))
                                .foregroundColor(Color(red: 0.434, green: 0.871, blue: 0.582))
//                        } else {
//                            Spacer()
//                                .frame(height: 14)
//                        }
                    }
                    
                    Spacer()
                    
                    if let fee = exchanger.fee {
                        VStack(alignment: .trailing) {
                            HStack(spacing: 4) {
                                Text(fee)
                                    .font(.Main.fixed(.bold, size: 16))
                                    .foregroundColor(Palette.grayScaleEA)

                                Text("btc")
                                    .font(.Main.fixed(.medium, size: 11))
                                    .foregroundColor(Palette.grayScale6A)
                                    .frame(width: 34)
                                    .offset(y: 2)
                            }
                            HStack(spacing: 4) {
                                Text("1.21")
                                    .font(.Main.fixed(.medium, size: 16))
                                    .foregroundColor(Palette.grayScale6A)

                                Text("usd")
                                    .font(.Main.fixed(.medium, size: 11))
                                    .foregroundColor(Palette.grayScale6A)
                                    .frame(width: 34)
                                    .offset(y: 2)
                            }
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .frame(height: 72)
                .transition(.opacity)
            } else {
                Spacer()
                    .frame(height: 72)
            }
            
            Spacer()
            
            if !exchanger.isValid {
                HStack {
                    Text("Not Enough Funds")
                        .font(.Main.fixed(.bold, size: 16))
                        .foregroundColor(warningColor)
                        .transition(.scale)
                    Spacer()
                }
                .padding(.bottom, 18)
            }
        }
    }
}

struct SetAmountView_Previews: PreviewProvider {
    static var previews: some View {
        SetAmountView(
            assetBalance: "0.001245", totalValue: "2.14",
            exchanger: Exchanger(
                coin: .bitcoin(),
                currency: .fiat(
                    FiatCurrency(code: "USD", name: "United States Dollar", rate: 1)
                )
            )
        )
        .padding()
    }
}
