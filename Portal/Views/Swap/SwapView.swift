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
import PortalSwapSDK

struct SwapView: View, IKeyboardReadable {
    @FocusState private var focusedField: Exchanger.Side?
    @State private var viewModel = SwapViewModel()
    
    @Injected(Container.viewState) private var viewState
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack {
                    Text("Swap")
                        .font(.Main.fixed(.bold, size: 24))
                        .foregroundColor(Palette.grayScaleF4)
                    
                    Spacer()
                    
                    Picker("Order side", selection: $viewModel.orderSide) {
                        Text("ASK").tag(Order.OrderSide.ask)
                        Text("BID").tag(Order.OrderSide.bid)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 110)
                }
                .frame(height: 49)
                .padding(.horizontal, 16)
                
                Divider()
                
                AssetSelectorView()
                    .frame(height: 178)
                    .padding(16)
                                
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
                case .start:
                    PButton(config: .onlyLabel("Swap"), style: .filled, size: .big, enabled: viewModel.actionButtonEnabled) {
                        focusedField = .none
                        viewModel.submitLimitOrder()
                    }
                    .padding(16)
                case .publishOrder:
                    HStack(spacing: 16) {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Publishing order...")
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(Palette.grayScaleF4)
                        Spacer()
                    }
                    .frame(height: 60)
                    .padding(16)
                case .matchingOrder:
                    HStack(spacing: 16) {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Matching...")
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(Palette.grayScaleF4)
                        Spacer()
                        PButton(config: .onlyLabel("Cancel"), style: .filled, size: .medium, enabled: true) {
                            viewModel.cancelOrder()
                        }
                    }
                    .frame(height: 60)
                    .padding(16)
                case .orderMatched:
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
                case .swapping:
                    HStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Swapping: \(viewModel.swapStatus ?? "")")
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(Palette.grayScaleF4)
                        Spacer()
                        VStack {
                            Text("Timeout")
                                .font(.Main.fixed(.monoBold, size: 12))
                                .foregroundColor(Palette.grayScaleEA)
                            Text(viewModel.timeoutString)
                                .font(.Main.fixed(.monoBold, size: 14))
                                .foregroundColor(Palette.grayScaleEA)
                        }
                    }
                    .frame(height: 60)
                    .padding(16)
                case .swapSucceed:
                    VStack {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(Color.green)
                            Text("Swap Succeeded!")
                                .font(.Main.fixed(.monoBold, size: 16))
                                .foregroundColor(Palette.grayScaleF4)
                        }
                        .padding(16)
                        
                        PButton(config: .onlyLabel("Ok"), style: .filled, size: .big, enabled: true) {
                            viewModel.clear()
                        }
                    }
                    .padding(16)
                case .swapError(let error):
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(Color.green)
                        
                        Text(error)
                            .font(.Main.fixed(.monoRegular, size: 16))
                            .foregroundColor(Color(red: 255/255, green: 82/255, blue: 82/255))
                            .padding(16)
                        
                        PButton(config: .onlyLabel("Dismiss"), style: .filled, size: .big, enabled: true) {
                            viewModel.clear()
                        }
                    }
                    .padding(16)
                    .frame(minHeight: 60)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.118, green: 0.118, blue: 0.118))
        .onReceive(keyboardPublisher) { newIsKeyboardVisible in
            if newIsKeyboardVisible {
                viewState.hideTabBar = true
                viewModel.bottomOffset = 0
            } else {
                viewState.hideTabBar = false
                viewModel.bottomOffset = 65
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
                            //                                    .onTapGesture {
                            //                                        viewModel.showPicker.toggle()
                            //                                    }
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
                            
                            HStack {
                                Text("Balance:")
                                    .font(.Main.fixed(.monoMedium, size: 14))
                                    .foregroundColor(Color(red: 0.29, green: 0.29, blue: 0.29))
                                
                                Text(viewModel.baseBalanceString)
                                    .font(.Main.fixed(.monoMedium, size: 14))
                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                            }
                            .frame(height: 14)
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
                            
                            HStack {
                                Text("Balance:")
                                    .font(.Main.fixed(.monoMedium, size: 14))
                                    .foregroundColor(Color(red: 0.29, green: 0.29, blue: 0.29))
                                
                                Text(viewModel.quoteBalanceString)
                                    .font(.Main.fixed(.monoMedium, size: 14))
                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                            }
                            .frame(height: 14)
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
                            //                                    .onTapGesture {
                            //                                        viewModel.showPicker.toggle()
                            //                                    }
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
                            
                            HStack {
                                Text("Balance:")
                                    .font(.Main.fixed(.monoMedium, size: 14))
                                    .foregroundColor(Color(red: 0.29, green: 0.29, blue: 0.29))
                                
                                Text(viewModel.quoteBalanceString)
                                    .font(.Main.fixed(.monoMedium, size: 14))
                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                            }
                            .frame(height: 14)
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
                            
                            HStack {
                                Text("Balance:")
                                    .font(.Main.fixed(.monoMedium, size: 14))
                                    .foregroundColor(Color(red: 0.29, green: 0.29, blue: 0.29))
                                
                                Text(viewModel.baseBalanceString)
                                    .font(.Main.fixed(.monoMedium, size: 14))
                                    .foregroundColor(Color(red: 0.416, green: 0.416, blue: 0.416))
                            }
                            .frame(height: 14)
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
        }
    }
}

struct SwapView_Previews: PreviewProvider {
    static var previews: some View {
        SwapView()
    }
}
