//
//  AmountView.swift
//  BDKDemoApp
//
//  Created by farid on 9/13/22.
//

import SwiftUI
import PortalUI
import Factory
import Combine

struct AmountView: View {
    private let warningColor = Color(red: 1, green: 0.321, blue: 0.321)
    @ObservedObject private var exchanger: Exchanger
    @FocusState private var focusedField: Exchanger.Side? 
    
    init(exchanger: Exchanger) {
        self.exchanger = exchanger
    }
    
    func limitText(_ upper: Int) {
        switch exchanger.side {
        case .crypto:
            print(exchanger.cryptoAmount.count)
            if exchanger.cryptoAmount.count > upper {
                exchanger.cryptoAmount = String(exchanger.cryptoAmount.prefix(upper))
            }
        case .currency:
            print(exchanger.cryptoAmount.count)
            if exchanger.currencyAmount.count > upper {
                exchanger.currencyAmount = String(exchanger.currencyAmount.prefix(upper))
            }
        }
    }
        
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                switch exchanger.side {
                case .crypto:
                    HStack(spacing: 8.5) {
                        Spacer()
                        TextField("0", text: $exchanger.cryptoAmount)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .crypto)
                            .onReceive(Just(exchanger.cryptoAmount)) { _ in limitText(10) }
                            .fixedSize(horizontal: true, vertical: true)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .font(.Main.fixed(.bold, size: 32))
                            .foregroundColor(exchanger.isValid ? Palette.grayScaleCA : warningColor)
                        Text("btc")
                            .font(.Main.fixed(.regular, size: 18))
                            .foregroundColor(Palette.grayScale6A)
                            .offset(y: 5)
                        Spacer()
                    }
                    .frame(maxWidth: 300)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                    HStack(spacing: 4) {
                        Text(exchanger.currencyAmount.isEmpty ? "0" : exchanger.currencyAmount)
                            .animation(nil)
                            .font(.Main.fixed(.medium, size: 16))
                            .foregroundColor(Palette.grayScale6A)
                        Text("usd")
                            .animation(nil)
                            .font(.Main.fixed(.medium, size: 12))
                            .foregroundColor(Palette.grayScale6A)
                            .offset(y: 2)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                case .currency:
                    HStack(spacing: 8.5) {
                        TextField("0", text: $exchanger.currencyAmount)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .currency)
                            .onReceive(Just(exchanger.currencyAmount)) { _ in limitText(10) }
                            .fixedSize(horizontal: true, vertical: true)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .font(.Main.fixed(.bold, size: 32))
                            .foregroundColor(exchanger.isValid ? Palette.grayScaleCA : warningColor)
                        Text("usd")
                            .font(.Main.fixed(.regular, size: 18))
                            .foregroundColor(Palette.grayScale6A)
                            .offset(y: 5)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                    HStack(spacing: 4) {
                        Spacer()
                        Text(exchanger.cryptoAmount.isEmpty ? "0" : exchanger.cryptoAmount)
                            .font(.Main.fixed(.medium, size: 16))
                            .foregroundColor(Palette.grayScale6A)
                        Text("btc")
                            .font(.Main.fixed(.medium, size: 12))
                            .foregroundColor(Palette.grayScale6A)
                            .offset(y: 2)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .offset(y: -3)
            
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.65, blendDuration: 0)) {
                    switch exchanger.side {
                    case .crypto:
                        exchanger.side = .currency
                    case .currency:
                        exchanger.side = .crypto
                    }
                }
            } label: {
                Asset.switchIcon
                    .resizable()
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(90))
                    .foregroundColor(Palette.grayScale6A)
            }
            .buttonStyle(.plain)
            
        }
        .frame(height: 90)
        .padding(.horizontal, 16)
        .background(Palette.grayScale1A)
        .cornerRadius(12)
        .onChange(of: exchanger.side, perform: { newValue in
            switch newValue {
            case .crypto:
                focusedField = .crypto
            case .currency:
                focusedField = .currency
            }
        })
        .onAppear {
            focusedField = .crypto
        }
    }
}

struct AmountView_Previews: PreviewProvider {
    static var previews: some View {
        AmountView(exchanger: Exchanger(
            coin: .bitcoin(),
            currency: .fiat(
                FiatCurrency(code: "USD", name: "United States Dollar", rate: 1)
            )
        ))
            .padding()
            .previewLayout(PreviewLayout.sizeThatFits)
    }
}
