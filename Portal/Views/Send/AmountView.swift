//
//  AmountView.swift
// Portal
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
    private let isValid: Bool
    
    @FocusState private var focusedField: Exchanger.Side?
    @ObservedObject private var exchanger: Exchanger
    @ObservedObject private var viewState = Container.viewState()
    
    init(exchanger: Exchanger, isValid: Bool, validate: Bool = true) {
        self.exchanger = exchanger
        self.validate = validate
        self.isValid = isValid
    }
        
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 2) {
                switch exchanger.side {
                case .base:
                    HStack(spacing: 8.5) {
                        Spacer()
                        TextField("0", text: $exchanger.amount.string)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .base)
                            .fixedSize(horizontal: true, vertical: true)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .font(.Main.fixed(.monoBold, size: 32))
                            .foregroundColor(
                                validate ? isValid ? Palette.grayScaleEA : warningColor : Palette.grayScaleEA
                            )
                        Text(exchanger.base.code.lowercased())
                            .font(.Main.fixed(.monoRegular, size: 18))
                            .foregroundColor(Palette.grayScale6A)
                            .offset(y: 5)
                        Spacer()
                    }
                    .frame(maxWidth: 300)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                    HStack(spacing: 4) {
                        Text(exchanger.quoteAmountString.isEmpty ? "0" : exchanger.quoteAmountString)
                            .animation(nil)
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Palette.grayScale6A)
                        Text(exchanger.quote.code.lowercased())
                            .animation(nil)
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Palette.grayScale6A)
                            .offset(y: 2)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                case .quote:
                    HStack(spacing: 8.5) {
                        TextField("0", text: $exchanger.amount.string)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .quote)
                            .fixedSize(horizontal: true, vertical: true)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .font(.Main.fixed(.monoBold, size: 32))
                            .foregroundColor(
                                validate ? isValid ? Palette.grayScaleEA : warningColor : Palette.grayScaleEA
                            )
                        Text(exchanger.quote.code.lowercased())
                            .font(.Main.fixed(.monoRegular, size: 18))
                            .foregroundColor(Palette.grayScale6A)
                            .offset(y: 5)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                    HStack(spacing: 4) {
                        Spacer()
                        Text(exchanger.amount.string.isEmpty ? "0" : exchanger.baseAmountString)
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Palette.grayScale6A)
                        Text(exchanger.base.code.lowercased())
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
                    case .base:
                        exchanger.side = .quote
                    case .quote:
                        exchanger.side = .base
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
            case .base:
                focusedField = .base
            case .quote:
                focusedField = .quote
            }
        })
        .onChange(of: viewState.showFeesPicker, perform: { newValue in
            if newValue {
                focusedField = nil
            } else {
                switch exchanger.side {
                case .base:
                    focusedField = .base
                case .quote:
                    focusedField = .quote
                }
            }
        })
        .onAppear {
            focusedField = .base
        }
    }
}

struct AmountView_Previews: PreviewProvider {
    static var previews: some View {
        AmountView(exchanger: Exchanger(
            base: .bitcoin(),
            quote: .fiat(
                FiatCurrency(code: "USD", name: "United States Dollar", rate: 1)
            ), price: 21000
        ), isValid: true)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
