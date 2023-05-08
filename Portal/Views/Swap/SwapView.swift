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
    @FocusState private var focusedField: Exchanger.Side?
    @StateObject private var viewModel = AtomicSwapViewModel()
    
    var starters = ["Ask", "Bid"]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Swap")
                            .font(.Main.fixed(.bold, size: 24))
                            .foregroundColor(Palette.grayScaleF4)
                    }
                    
                    Text(viewModel.description)
                        .font(.Main.fixed(.bold, size: 16))
                        .foregroundColor(.yellow)
                        .opacity(0)
                    
                    Spacer()
                    
                    Picker("Order side", selection: $viewModel.orderSide) {
                        Text("ask").tag(Order.OrderSide.ask)
                        Text("bid").tag(Order.OrderSide.bid)
                    }
                    .pickerStyle(.segmented)
                }
                .frame(height: 49)
                .padding(.horizontal, 16)
                
                Divider()
                
                AssetSelectorView()
                    .frame(height: 178)
                    .padding(16)
                
                if let order = viewModel.order {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundColor(.black.opacity(0.5))
                        
                        VStack {
                            HStack {
                                Text("order id:")
                                    .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                                Spacer()
                                Text(order.id)
                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                            }
                            
                            HStack {
                                Text("uid:")
                                    .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                                Spacer()
                                Text(order.uid)
                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                            }
                            
                            HStack {
                                Text("hash:")
                                    .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                                Spacer()
                                Text(order.hash)
                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                            }
                            
                            HStack {
                                Text("base:")
                                    .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                                Spacer()
                                Text(order.baseAsset)
                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                            }
                            
                            HStack {
                                Text("quote:")
                                    .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                                Spacer()
                                Text(order.quoteAsset)
                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                            }
                            
                            HStack {
                                Text("status:")
                                    .foregroundColor(Color(red: 0.792, green: 0.792, blue: 0.792))
                                Spacer()
                                Text(order.status.rawValue)
                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                            }
                        }
                        .font(.Main.fixed(.monoMedium, size: 12))
                        .padding(10)
                    }
                    .padding(20)
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
                
                switch viewModel.swapState {
                case .create, .canceled:
                    VStack(alignment: .leading, spacing: 16) {
                        PButton(config: .onlyLabel("Submit"), style: .filled, size: .big, enabled: viewModel.actionButtonEnabled) {
                            Task {
                                try await viewModel.submitLimitOrder()
                            }
                        }
                    }
                    .padding(16)
                case .matching:
                    VStack {
                        HStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Waiting for Match...")
                                .font(.Main.fixed(.monoBold, size: 16))
                                .foregroundColor(Palette.grayScaleF4)
                        }
                        .frame(height: 60)
                        
//                        VStack(alignment: .leading, spacing: 16) {
//                            PButton(config: .onlyLabel("Commit"), style: .filled, size: .big, enabled: viewModel.actionButtonEnabled) {
//                                Task {
//                                    await viewModel.commitSwap()
//                                }
//                            }
//
//                        }
                    }
                    .padding(16)
                case .matched:
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(Color.green)
                        Text("Order Matched")
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(Palette.grayScaleF4)
                    }
                    .frame(height: 60)
                    .padding(16)
                case .open:
                    VStack {
//                        HStack(spacing: 16) {
//                            ProgressView()
//                                .progressViewStyle(CircularProgressViewStyle())
//                            Text("Waiting for Match...")
//                                .font(.Main.fixed(.monoBold, size: 16))
//                                .foregroundColor(Palette.grayScaleF4)
//                        }
//                        .frame(height: 60)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            PButton(config: .onlyLabel("Open"), style: .filled, size: .big, enabled: viewModel.actionButtonEnabled) {
                                Task {
                                    await viewModel.openSwap()
                                }
                            }

                        }
                    }
                    .padding(16)

                case .commit:
                    VStack {
                        HStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Text("Swapping...")
                                .font(.Main.fixed(.monoBold, size: 16))
                                .foregroundColor(Palette.grayScaleF4)
                        }
                        .frame(height: 60)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            PButton(config: .onlyLabel("Commit"), style: .filled, size: .big, enabled: false) {
                                Task {
                                    await viewModel.commitSwap()
                                }
                            }

                        }
                    }
                    .padding(16)
                case .commiting:
                    HStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Swapping...")
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(Palette.grayScaleF4)
                    }
                    .frame(height: 60)
                    .padding(16)
                case .commited:
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(Color.green)
                        Text("Swapped!")
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(Palette.grayScaleF4)
                    }
                    .frame(height: 60)
                    .padding(16)
                }
            }
            .background(
                Palette.grayScale2A.edgesIgnoringSafeArea(.bottom)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(1)
            .padding(.bottom, viewModel.bottomOffset)
        }
        .padding(.horizontal, 6)
        .sheet(isPresented: $viewModel.goToReview, content: {
            SwapReviewView(base: viewModel.base!, baseAmount: viewModel.baseAmount, quote: viewModel.quote!, quoteAmount: viewModel.quoteAmount)
        })
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.118, green: 0.118, blue: 0.118))
        .onReceive(keyboardPublisher) { newIsKeyboardVisible in
//            if newIsKeyboardVisible {
//                viewModel.viewState.hideTabBar.toggle()
//                viewModel.bottomOffset = 0
//            } else {
//                viewModel.viewState.hideTabBar.toggle()
//                viewModel.bottomOffset = 65
//            }
        }
    }
    
    func AssetSelectorView() -> some View {
        ZStack {
//            switch viewModel.swapState {
//            case .create, .canceled, .commited:
                RoundedRectangle(cornerRadius: 8)
                    .foregroundColor(.black)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.227, green: 0.227, blue: 0.227), lineWidth: 2)
                    }
                
                VStack(spacing: 0) {
                    switch viewModel.exchangerSide {
                    case .base:
                        VStack(spacing: 8) {
                            HStack(spacing: 0) {
                                TextField("0", text: $viewModel.baseAmount)
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .base)
                                    .fixedSize(horizontal: true, vertical: true)
                                    .disableAutocorrection(true)
                                    .textInputAutocapitalization(.never)
                                    .font(.Main.fixed(.monoBold, size: 26))
                                
                                Spacer()
                                
                                SwapCoinView(coin: viewModel.base)
                                    .onTapGesture {
                                        viewModel.showPicker.toggle()
                                    }
                            }
                            .frame(height: 32)
                            .padding(.leading, 24)
                            .padding(.trailing, 16)
                            
                            HStack(spacing: 0) {
                                if let decimal = Decimal(string: viewModel.baseAmount), decimal > 0 {
                                    Text("\(viewModel.baseAmountValue) usd")
                                        .font(.Main.fixed(.monoMedium, size: 16))
                                        .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                                        .frame(height: 16)
                                }
                                
                                Spacer()
                                
                                if viewModel.base != nil {
                                    HStack {
                                        Text("Balance:")
                                            .font(.Main.fixed(.monoMedium, size: 14))
                                            .foregroundColor(Color(red: 0.29, green: 0.29, blue: 0.29))
                                        
                                        Text(viewModel.L1Balance)
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
                                TextField("0", text: $viewModel.quoteAmount)
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .quote)
                                    .fixedSize(horizontal: true, vertical: true)
                                    .disableAutocorrection(true)
                                    .textInputAutocapitalization(.never)
                                    .font(.Main.fixed(.monoBold, size: 26))
                                
                                Spacer()
                                
                                SwapCoinView(coin: viewModel.quote)
                            }
                            .frame(height: 32)
                            .padding(.leading, 24)
                            .padding(.trailing, 16)
                            
                            HStack(spacing: 0) {
                                if let decimal = Decimal(string: viewModel.quoteAmount), decimal > 0 {
                                    Text("\(viewModel.quoteAmountValue) usd")
                                        .font(.Main.fixed(.monoMedium, size: 16))
                                        .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                                        .frame(height: 16)
                                }
                                
                                Spacer()
                                
                                if viewModel.base != nil {
                                    HStack {
                                        Text("Balance:")
                                            .font(.Main.fixed(.monoMedium, size: 14))
                                            .foregroundColor(Color(red: 0.29, green: 0.29, blue: 0.29))
                                        
                                        Text(viewModel.L2Balance)
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
                                TextField("0", text: $viewModel.quoteAmount)
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .quote)
                                    .fixedSize(horizontal: true, vertical: true)
                                    .disableAutocorrection(true)
                                    .textInputAutocapitalization(.never)
                                    .font(.Main.fixed(.monoBold, size: 26))
                                
                                Spacer()
                                
                                SwapCoinView(coin: viewModel.quote)
                                    .onTapGesture {
                                        viewModel.showPicker.toggle()
                                    }
                            }
                            .frame(height: 32)
                            .padding(.leading, 24)
                            .padding(.trailing, 16)
                            
                            HStack(spacing: 0) {
                                if let decimal = Decimal(string: viewModel.quoteAmount), decimal > 0 {
                                    Text("\(viewModel.quoteAmountValue) usd")
                                        .font(.Main.fixed(.monoMedium, size: 16))
                                        .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                                        .frame(height: 16)
                                }
                                
                                Spacer()
                                
                                if viewModel.base != nil {
                                    HStack {
                                        Text("Balance:")
                                            .font(.Main.fixed(.monoMedium, size: 14))
                                            .foregroundColor(Color(red: 0.29, green: 0.29, blue: 0.29))
                                        
                                        Text(viewModel.L2Balance)
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
                                TextField("0", text: $viewModel.baseAmount)
                                    .keyboardType(.decimalPad)
                                    .focused($focusedField, equals: .base)
                                    .fixedSize(horizontal: true, vertical: true)
                                    .disableAutocorrection(true)
                                    .textInputAutocapitalization(.never)
                                    .font(.Main.fixed(.monoBold, size: 26))
                                
                                Spacer()
                                
                                SwapCoinView(coin: viewModel.base)
                            }
                            .frame(height: 32)
                            .padding(.leading, 24)
                            .padding(.trailing, 16)
                            
                            HStack(spacing: 0) {
                                if let decimal = Decimal(string: viewModel.baseAmount), decimal > 0 {
                                    Text("\(viewModel.baseAmountValue) usd")
                                        .font(.Main.fixed(.monoMedium, size: 16))
                                        .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                                        .frame(height: 16)
                                }
                                
                                Spacer()
                                
                                if viewModel.base != nil {
                                    HStack {
                                        Text("Balance:")
                                            .font(.Main.fixed(.monoMedium, size: 14))
                                            .foregroundColor(Color(red: 0.29, green: 0.29, blue: 0.29))
                                        
                                        Text(viewModel.L1Balance)
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
                                switch viewModel.exchangerSide {
                                case .base:
                                    viewModel.exchangerSide = .quote
                                case .quote:
                                    viewModel.exchangerSide = .base
                                }
                            }
                        }
                }
                .frame(width: 32, height: 32)
//            case .open, .commit:
//                VStack {
//                    VStack(spacing: 8) {
//                        HStack(spacing: 0) {
//                            TextField("0", text: .constant(viewModel.baseAmount))
//                                .keyboardType(.decimalPad)
//                                .fixedSize(horizontal: true, vertical: true)
//                                .disableAutocorrection(true)
//                                .textInputAutocapitalization(.never)
//                                .font(.Main.fixed(.monoBold, size: 26))
//
//                            Spacer()
//
//                            SwapCoinView(coin: viewModel.base)
//                        }
//                        .frame(height: 32)
//                        .padding(.leading, 20)
//                        .padding(.trailing, 8)
//
//                        HStack(spacing: 0) {
//                            if let decimal = Decimal(string: viewModel.baseAmount), decimal > 0 {
//                                Text("\(viewModel.baseAmountValue) usd")
//                                    .font(.Main.fixed(.monoMedium, size: 16))
//                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
//                                    .frame(height: 16)
//                            }
//
//                            Spacer()
//                        }
//                        .padding(.leading, 20)
//                        .padding(.trailing, 8)
//                    }
//                    .frame(height: 65)
//
//                    HStack {
//                        PButton(config: .onlyLabel("~ swapping for"), style: .free, size: .small, applyGradient: true, enabled: true) {
//
//                        }
//                        .frame(width: 160)
//
//                        Spacer()
//                    }
//                    .padding(.leading, 30)
//
//                    VStack(spacing: 8) {
//                        HStack(spacing: 0) {
//                            TextField("0", text: .constant(viewModel.quoteAmount))
//                                .keyboardType(.decimalPad)
//                                .fixedSize(horizontal: true, vertical: true)
//                                .disableAutocorrection(true)
//                                .textInputAutocapitalization(.never)
//                                .font(.Main.fixed(.monoBold, size: 26))
//
//                            Spacer()
//
//                            SwapCoinView(coin: viewModel.quote)
//                        }
//                        .frame(height: 32)
//                        .padding(.leading, 20)
//                        .padding(.trailing, 8)
//
//                        HStack(spacing: 0) {
//                            if let decimal = Decimal(string: viewModel.quoteAmount), decimal > 0 {
//                                Text("\(viewModel.quoteAmountValue) usd")
//                                    .font(.Main.fixed(.monoMedium, size: 16))
//                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
//                                    .frame(height: 16)
//                            }
//
//                            Spacer()
//                        }
//                        .padding(.leading, 20)
//                        .padding(.trailing, 8)
//                    }
//                    .frame(height: 65)
//                }
//
//                Spacer()
//            }
        }
        
    }
}

struct SwapView_Previews: PreviewProvider {
    static var previews: some View {
        SwapView()
    }
}
