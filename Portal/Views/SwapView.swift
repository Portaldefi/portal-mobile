//
//  SwapView.swift
//  Portal
//
//  Created by farid on 1/13/23.
//

import SwiftUI
import PortalUI
import Factory
import Combine

struct SwapCoinView: View {
    let coin: Coin?
    
    var body: some View {
        HStack(spacing: 6) {
            if let coin = coin {
                CoinImageView(size: 16, url: coin.icon)
                Text(coin.code.uppercased())
                    .font(.Main.fixed(.bold, size: 18))
                    .foregroundColor(.white)
            } else {
                Text("select")
                    .font(.Main.fixed(.bold, size: 12))
                    .foregroundColor(.white)
                    .frame(height: 32)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(Color(red: 0.125, green: 0.125, blue: 0.125))
        }
    }
}

protocol KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> { get }
}

extension KeyboardReadable {
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers.Merge(
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillShowNotification)
                .map { _ in true },
            
            NotificationCenter.default
                .publisher(for: UIResponder.keyboardWillHideNotification)
                .map { _ in false }
        )
        .eraseToAnyPublisher()
    }
}

struct SwapView: View, KeyboardReadable {
    enum SwapSide: Int, Hashable {
        case base, quote
    }
    
    @State var swapSide: SwapSide = .base
    @State var base: Coin? = .bitcoin()
    @State var quote: Coin? = .ethereum()
    @State var baseAmount = String()
    @State var quoteAmount = String()
    @State var showPicker = false
    @State var actionButtonEnabled = false
    @State var bottomOffset: CGFloat = 65
    @State var goToReview = false
    
    @ObservedObject var viewState = Container.viewState()
    
    @FocusState private var focusedField: SwapSide?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Swap")
                            .font(.Main.fixed(.bold, size: 24))
                            .foregroundColor(Palette.grayScaleF4)
                        
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 4)
                                .foregroundColor(Color(red: 0.191, green: 0.858, blue: 0.418))
                                .frame(width: 16, height: 16)
                            Text("All systems ok!")
                                .font(.Main.fixed(.regular, size: 14))
                                .foregroundColor(Color(red: 0.191, green: 0.858, blue: 0.418))
                        }
                    }
                    
                    Spacer()
                    
                    HStack {
                        Divider()
                            .frame(width: 1)
                        Asset.gearIcon
                            .foregroundColor(Palette.grayScale6A)
                            .padding(.horizontal, 8)
                        
                    }
                }
                .frame(height: 73)
                .padding(.horizontal, 16)
                
                Divider()
                
                AssetSelectorView()
                    .frame(height: 178)
                    .padding(16)
                
                if actionButtonEnabled {
                    HStack {
                        Text("1 btc")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                        Text("=")
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                        Text("13.789224 eth")
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                        Text("Fees")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                        Text("1,4000")
                        Text("Sats")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                    }
                }
                
                Rectangle()
                    .foregroundColor(Color(red: 0.118, green: 0.118, blue: 0.118))
                    .onTapGesture {
                        focusedField = .none
                    }
            }
            
            VStack(spacing: 0) {
                Divider()
                    .frame(height: 1)
                    .overlay(Palette.grayScale4A)
                
                VStack(alignment: .leading, spacing: 16) {
                    PButton(config: .onlyLabel("Swap"), style: .filled, size: .big, enabled: actionButtonEnabled) {
                        goToReview = true
                    }
                    
                }
                .padding(16)
            }
            .background(
                Palette.grayScale2A.edgesIgnoringSafeArea(.bottom)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(1)
            .padding(.bottom, bottomOffset)
        }
        .sheet(isPresented: $goToReview, content: {
            SwapReviewView(base: base!, baseAmount: baseAmount, quote: quote!, quoteAmount: quoteAmount)
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.118, green: 0.118, blue: 0.118))
        .onReceive(keyboardPublisher) { newIsKeyboardVisible in
            if newIsKeyboardVisible {
                viewState.hideTabBar = true
                bottomOffset = 0
            } else {
                viewState.hideTabBar = false
                bottomOffset = 65
            }
        }
    }
    
    func AssetSelectorView() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(.black)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.227, green: 0.227, blue: 0.227), lineWidth: 2)
                }
            
            VStack(spacing: 0) {
                switch swapSide {
                case .base:
                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            TextField("0", text: $baseAmount)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .base)
                                .fixedSize(horizontal: true, vertical: true)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .font(.Main.fixed(.monoBold, size: 26))
                                .onChange(of: baseAmount) { newValue in
                                    if let decimal = Decimal(string: newValue), decimal > 0 {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            withAnimation {
                                                quoteAmount = "0.01243"
                                                actionButtonEnabled = true
                                            }
                                        }
                                    } else {
                                        quoteAmount = String()
                                        actionButtonEnabled = false
                                    }
                                }
                            
                            Spacer()
                            
                            SwapCoinView(coin: base)
                                .onTapGesture {
                                    showPicker.toggle()
                                }
                        }
                        .frame(height: 32)
                        .padding(.leading, 24)
                        .padding(.trailing, 16)
                        
                        HStack(spacing: 0) {
                            if let decimal = Decimal(string: baseAmount), decimal > 0 {
                                Text("1,293.00 usd")
                                    .font(.Main.fixed(.monoMedium, size: 16))
                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                                    .frame(height: 16)
                            }
                            
                            Spacer()
                            
                            if base != nil {
                                HStack {
                                    Text("Balance:")
                                        .font(.Main.fixed(.monoMedium, size: 14))
                                        .foregroundColor(Color(red: 0.29, green: 0.29, blue: 0.29))
                                    
                                    Text("0.00067")
                                        .font(.Main.fixed(.monoMedium, size: 14))
                                        .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                                }
                                .frame(height: 14)
                            }
                        }
                        .padding(.leading, 24)
                        .padding(.trailing, 16)
                    }
                    .frame(height: 88)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            TextField("0", text: $quoteAmount)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .base)
                                .fixedSize(horizontal: true, vertical: true)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .font(.Main.fixed(.monoBold, size: 26))
                            
                            Spacer()
                            
                            SwapCoinView(coin: quote)
                        }
                        .frame(height: 32)
                        .padding(.leading, 24)
                        .padding(.trailing, 16)
                        
                        HStack(spacing: 0) {
                            Spacer()
                            
                            if quote != nil {
                                HStack {
                                    Text("Balance:")
                                        .font(.Main.fixed(.monoMedium, size: 14))
                                        .foregroundColor(Color(red: 0.29, green: 0.29, blue: 0.29))
                                    
                                    Text("0.061311207")
                                        .font(.Main.fixed(.monoMedium, size: 14))
                                        .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                                }
                                .frame(height: 14)
                            }
                        }
                        .padding(.leading, 24)
                        .padding(.trailing, 16)
                    }
                    .frame(height: 88)
                    .transition(.move(edge: .top).combined(with: .opacity))
                case .quote:
                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            TextField("0", text: $quoteAmount)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .base)
                                .fixedSize(horizontal: true, vertical: true)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .font(.Main.fixed(.monoBold, size: 26))
                            
                            Spacer()
                            
                            SwapCoinView(coin: quote)
                                .onTapGesture {
                                    showPicker.toggle()
                                }
                        }
                        .frame(height: 32)
                        .padding(.leading, 24)
                        .padding(.trailing, 16)
                        
                        HStack(spacing: 0) {
                            if let decimal = Decimal(string: quoteAmount), decimal > 0 {
                                Text("1,293.00 usd")
                                    .font(.Main.fixed(.monoMedium, size: 16))
                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                                    .frame(height: 16)
                            }
                            
                            Spacer()
                            
                            if base != nil {
                                HStack {
                                    Text("Balance:")
                                        .font(.Main.fixed(.monoMedium, size: 14))
                                        .foregroundColor(Color(red: 0.29, green: 0.29, blue: 0.29))
                                    
                                    Text("0.061311207")
                                        .font(.Main.fixed(.monoMedium, size: 14))
                                        .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                                }
                                .frame(height: 14)
                            }
                        }
                        .padding(.leading, 24)
                        .padding(.trailing, 16)
                    }
                    .frame(height: 88)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 0) {
                            TextField("0", text: $baseAmount)
                                .keyboardType(.decimalPad)
                                .focused($focusedField, equals: .base)
                                .fixedSize(horizontal: true, vertical: true)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .font(.Main.fixed(.monoBold, size: 26))
                            
                            Spacer()
                            
                            SwapCoinView(coin: base)
                        }
                        .frame(height: 32)
                        .padding(.leading, 24)
                        .padding(.trailing, 16)
                        
                        HStack(spacing: 0) {
                            if let decimal = Decimal(string: baseAmount), decimal > 0 {
                                Text("1,293.00 usd")
                                    .font(.Main.fixed(.monoMedium, size: 16))
                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                                    .frame(height: 16)
                            }
                            
                            Spacer()
                            
                            if base != nil {
                                HStack {
                                    Text("Balance:")
                                        .font(.Main.fixed(.monoMedium, size: 14))
                                        .foregroundColor(Color(red: 0.29, green: 0.29, blue: 0.29))
                                    
                                    Text("0.00067")
                                        .font(.Main.fixed(.monoMedium, size: 14))
                                        .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                                }
                                .frame(height: 14)
                            }
                        }
                        .padding(.leading, 24)
                        .padding(.trailing, 16)
                    }
                    .frame(height: 88)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            
            Divider()
                .frame(height: 2)
                .foregroundColor(Color(red: 0.227, green: 0.227, blue: 0.227))
            
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(Color(red: 0.125, green: 0.125, blue: 0.125))
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.227, green: 0.227, blue: 0.227), lineWidth: 2)
                    }
                
                Asset.switchIcon.resizable().frame(width: 22, height: 22).rotationEffect(.degrees(90))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.65, blendDuration: 0)) {
                            switch swapSide {
                            case .base:
                                swapSide = .quote
                            case .quote:
                                swapSide = .base
                            }
                        }
                    }
            }
            .frame(width: 32, height: 32)
        }
        
    }
}

struct SwapView_Previews: PreviewProvider {
    static var previews: some View {
        SwapView(base: .bitcoin(), quote: .ethereum())
    }
}
