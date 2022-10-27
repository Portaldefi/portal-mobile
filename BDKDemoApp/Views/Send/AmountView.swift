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
    private let validate: Bool
    @ObservedObject private var exchanger: Exchanger
    @FocusState private var focusedField: Exchanger.Side?
    @ObservedObject private var viewState = Container.viewState()
    
    init(exchanger: Exchanger, validate: Bool = true) {
        self.exchanger = exchanger
        self.validate = validate
    }
    
    func limitText(_ upper: Int) {
        switch exchanger.side {
        case .crypto:
            if exchanger.cryptoAmount.count > upper {
                exchanger.cryptoAmount = String(exchanger.cryptoAmount.prefix(upper))
            }
        case .currency:
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
                            .font(.Main.fixed(.monoBold, size: 32))
                            .foregroundColor(
                                validate ? exchanger.amountIsValid ? Palette.grayScaleEA : warningColor : Palette.grayScaleEA
                            )
                        Text("btc")
                            .font(.Main.fixed(.monoRegular, size: 18))
                            .foregroundColor(Palette.grayScale6A)
                            .offset(y: 5)
                        Spacer()
                    }
                    .frame(maxWidth: 300)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                    HStack(spacing: 4) {
                        Text(exchanger.currencyAmount.isEmpty ? "0" : exchanger.currencyAmount)
                            .animation(nil)
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Palette.grayScale6A)
                        Text("usd")
                            .animation(nil)
                            .font(.Main.fixed(.monoMedium, size: 12))
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
                            .font(.Main.fixed(.monoBold, size: 32))
                            .foregroundColor(
                                validate ? exchanger.amountIsValid ? Palette.grayScaleEA : warningColor : Palette.grayScaleEA
                            )
                        Text("usd")
                            .font(.Main.fixed(.monoRegular, size: 18))
                            .foregroundColor(Palette.grayScale6A)
                            .offset(y: 5)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                    HStack(spacing: 4) {
                        Spacer()
                        Text(exchanger.cryptoAmount.isEmpty ? "0" : exchanger.cryptoAmount)
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Palette.grayScale6A)
                        Text("btc")
                            .font(.Main.fixed(.monoMedium, size: 12))
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
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 58/255, green: 58/255, blue: 58/255), lineWidth: 1)
                .foregroundColor(Color.clear)
        )
        .onChange(of: exchanger.side, perform: { newValue in
            switch newValue {
            case .crypto:
                focusedField = .crypto
            case .currency:
                focusedField = .currency
            }
        })
        .onChange(of: viewState.showFeesPicker, perform: { newValue in
            if newValue {
                focusedField = nil
            } else {
                switch exchanger.side {
                case .crypto:
                    focusedField = .crypto
                case .currency:
                    focusedField = .currency
                }
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
            base: .bitcoin(),
            quote: .fiat(
                FiatCurrency(code: "USD", name: "United States Dollar", rate: 1)
            ), balanceAdapter: BalanceAdapterMocked()
        ))
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
