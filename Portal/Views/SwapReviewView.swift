//
//  SwapReviewView.swift
//  Portal
//
//  Created by farid on 1/13/23.
//

import SwiftUI
import PortalUI

struct SwapReviewView: View {
    @Environment(\.presentationMode) private var presentationMode

    let base: Coin
    let baseAmount: String
    let quote: Coin
    let quoteAmount: String
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                ZStack {
                    Text("Review Swap")
                        .font(.Main.fixed(.monoBold, size: 16))

                    
                    HStack {
                        PButton(config: .onlyIcon(Asset.xIcon), style: .free, size: .medium, enabled: true) {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .frame(width: 28, height: 28)
                        Spacer()
                    }
                }
                .padding()
                
                Divider()
                    .padding(.horizontal)
                
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        TextField("0", text: .constant(baseAmount))
                            .keyboardType(.decimalPad)
                            .fixedSize(horizontal: true, vertical: true)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .font(.Main.fixed(.monoBold, size: 26))
                        
                        Spacer()
                        
                        SwapCoinView(coin: base)
                    }
                    .frame(height: 32)
                    .padding(.leading, 40)
                    .padding(.trailing, 16)
                    
                    HStack(spacing: 0) {
                        if let decimal = Decimal(string: baseAmount), decimal > 0 {
                            Text("1,293.00 usd")
                                .font(.Main.fixed(.monoMedium, size: 16))
                                .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                                .frame(height: 16)
                        }
                        
                        Spacer()
                    }
                    .padding(.leading, 40)
                    .padding(.trailing, 16)
                }
                .frame(height: 88)
                
                HStack {
                    PButton(config: .onlyLabel("~ swapping for"), style: .free, size: .small, applyGradient: true, enabled: true) {
                        
                    }
                    .frame(width: 160)
                    
                    Spacer()
                }
                .padding(.leading, 30)
                
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        TextField("0", text: .constant(quoteAmount))
                            .keyboardType(.decimalPad)
                            .fixedSize(horizontal: true, vertical: true)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .font(.Main.fixed(.monoBold, size: 26))
                        
                        Spacer()
                        
                        SwapCoinView(coin: quote)
                    }
                    .frame(height: 32)
                    .padding(.leading, 40)
                    .padding(.trailing, 16)
                    
                    HStack(spacing: 0) {
                        if let decimal = Decimal(string: quoteAmount), decimal > 0 {
                            Text("1,293.00 usd")
                                .font(.Main.fixed(.monoMedium, size: 16))
                                .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                                .frame(height: 16)
                        }
                        
                        Spacer()
                    }
                    .padding(.leading, 40)
                    .padding(.trailing, 16)
                }
                .frame(height: 88)
                
                Divider()
                    .padding(.horizontal)
                
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                        Text("Network Costs")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Color(red: 0.541, green: 0.541, blue: 0.541))
                    }
                    HStack {
                        Text("Connect to channel")
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                        Spacer()
                        Text("150 sats")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                    }
                    
                    HStack {
                        Text("Move funds to Instant")
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                        Spacer()
                        Text("150 sats")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                    }
                    
                    HStack {
                        Text("Buy outbound liquidity")
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                        Spacer()
                        Text("150 sats")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                    }
                    
                    HStack {
                        Text("Buy inbound liquidity")
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                        Spacer()
                        Text("150 sats")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                    }
                    
                    HStack {
                        Text("Routing Fee")
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                        Spacer()
                        Text("150 sats")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                    }
                    HStack {
                        Spacer()
                        Text("Facillitator Fees")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Color(red: 0.541, green: 0.541, blue: 0.541))
                    }
                    
                    HStack {
                        Text("Order Publishing")
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                        Spacer()
                        Text("150 sats")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                    }
                    
                    HStack {
                        Text("Swap Relay")
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                        Spacer()
                        Text("150 sats")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)

                
                Divider()
                    .padding(.horizontal)
                                
                Spacer()
            }
            
            VStack(spacing: 0) {
                Divider()
                    .frame(height: 1)
                    .overlay(Palette.grayScale4A)
                
                VStack(alignment: .leading, spacing: 16) {
                    PButton(config: .onlyLabel("Commit & Lock Funds"), style: .filled, size: .big, enabled: true) {
                        withAnimation {
                            //viewModel.onActionButtonPressed()
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
        .background(.black)
    }
}

struct SwapReviewView_Previews: PreviewProvider {
    static var previews: some View {
        SwapReviewView(base: .bitcoin(), baseAmount: "0.124", quote: .ethereum(), quoteAmount: "1.7632")
    }
}
