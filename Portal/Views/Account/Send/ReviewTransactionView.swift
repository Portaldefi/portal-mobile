//
//  ReviewTransactionView.swift
// Portal
//
//  Created by farid on 26/8/22.
//

import SwiftUI
import PortalUI
import Factory
import BitcoinDevKit
import PopupView
import Lightning

struct ReviewTransactionView: View {
    @FocusState private var isFocused: Bool
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewModel: SendViewViewModel
    @EnvironmentObject private var navigation: NavigationStack
    @State private var step: ReviewStep = .reviewing
    @State private var actionButtonEnabled = true
    @State private var editingAmount = false
    
    enum ReviewStep {
        case reviewing, signing, sent
    }
    
    private var title: String {
        switch step {
        case .reviewing:
            return "Review Transaction"
        case .signing:
            return "Singing..."
        case .sent:
            return "Sent"
        }
    }
    
    private var backButtonEnabled: Bool {
        switch step {
        case .signing, .sent:
            return false
        default:
            return true
        }
    }
    
    init(viewModel: SendViewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ZStack {
                    if backButtonEnabled {
                        HStack {
                            PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                                navigation.pop()
                            }
                            .frame(width: 20)
                            
                            Spacer()
                        }
                    }
                    
                    Text(title)
                        .frame(width: 300, height: 62)
                        .font(.Main.fixed(.monoBold, size: 16))
                }
                
                HStack(alignment: .top, spacing: 16) {
                    Text("Recipient")
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(Palette.grayScaleAA)
                    
                    Text(viewModel.receiverAddress)
                        .font(.Main.fixed(.monoRegular, size: 16))
                        .foregroundColor(Palette.grayScaleF4)
                }
                .padding(.vertical, 16)
                
                Divider()
                    .frame(height: 1)
                
                Button {
                    if viewModel.showFeesPicker  {
                        viewModel.showFeesPicker.toggle()
                    }
                    editingAmount.toggle()
                } label: {
                    ZStack(alignment: .trailing) {
                        VStack {
                            if let exchanger = viewModel.exchanger {
                                HStack(alignment: .top, spacing: 16) {
                                    Text("Amount")
                                        .font(.Main.fixed(.monoBold, size: 14))
                                        .foregroundColor(Palette.grayScaleAA)
                                    
                                    Spacer()
                                    
                                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                                        VStack(alignment: .trailing, spacing: 6) {
                                            Text(exchanger.baseAmountString)
                                                .font(.Main.fixed(.monoBold, size: 32))
                                                .foregroundColor(viewModel.amountIsValid ? Palette.grayScaleEA : Color(red: 1, green: 0.349, blue: 0.349))
                                                .frame(height: 26)
                                            
                                            Text(exchanger.quoteAmountString)
                                                .font(.Main.fixed(.monoMedium, size: 16))
                                                .foregroundColor(Palette.grayScale6A)
                                            
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(exchanger.base.code.lowercased())
                                                .font(.Main.fixed(.monoRegular, size: 18))
                                                .foregroundColor(Palette.grayScale6A)
                                            
                                            Text(exchanger.quote.code.lowercased())
                                                .font(.Main.fixed(.monoMedium, size: 12))
                                                .foregroundColor(Palette.grayScale6A)
                                        }
                                        .padding(.bottom, 2)
                                    }
                                }
                                
                                if !viewModel.amountIsValid {
                                    HStack(spacing: 6) {
                                        Spacer()
                                        Text("Not enough funds.")
                                            .font(.Main.fixed(.monoMedium, size: 12))
                                        Text("Tap to Edit")
                                            .font(.Main.fixed(.monoSemiBold, size: 12))
                                    }
                                    .foregroundColor(Color(red: 1, green: 0.349, blue: 0.349))
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        
                        Asset.chevronRightIcon
                            .foregroundColor(Palette.grayScale4A)
                            .offset(x: 18)
                    }
                }
                
                Divider()
                    .frame(height: 1)
                
                switch try? viewModel.validateInput() {
                case .btcOnChain, .ethOnChain:
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Transaction Fees")
                                .font(.Main.fixed(.monoBold, size: 14))
                                .foregroundColor(Palette.grayScaleAA)
                            Text(viewModel.feeRate.description)
                                .font(.Main.fixed(.monoRegular, size: 14))
                                .foregroundColor(Color(red: 0.191, green: 0.858, blue: 0.418))
                        }
                        
                        Spacer()
                        
                        if let coin = viewModel.coin {
                            VStack {
                                HStack(spacing: 6) {
                                    Text(viewModel.fee)
                                        .font(.Main.fixed(.monoBold, size: 16))
                                        .foregroundColor(Palette.grayScaleEA)
                                    
                                    switch coin.type {
                                    case .bitcoin, .lightningBitcoin:
                                        Text("btc")
                                            .font(.Main.fixed(.monoMedium, size: 11))
                                            .foregroundColor(Palette.grayScale6A)
                                            .frame(width: 34)
                                    case .ethereum, .erc20:
                                        Text("eth")
                                            .font(.Main.fixed(.monoMedium, size: 11))
                                            .foregroundColor(Palette.grayScale6A)
                                            .frame(width: 34)
                                    }
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        } else {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                    }
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if editingAmount {
                            editingAmount.toggle()
                        }
                        
                        if let coin = viewModel.coin, coin == .bitcoin() {
                            viewModel.showFeesPicker.toggle()
                        }
                    }
                    
                    Divider()
                        .frame(height: 1)
                case .lightningInvoice, .none:
                    EmptyView()
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                Divider()
                    .frame(height: 1)
                    .overlay(Palette.grayScale4A)
                
                switch step {
                case .reviewing:
                    VStack(alignment: .leading, spacing: 16) {
                        if !viewModel.amountIsValid {
                            Text("Not enough funds")
                                .font(.Main.fixed(.monoRegular, size: 16))
                                .foregroundColor(Color(red: 255/255, green: 82/255, blue: 82/255))
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        if let errorMessage = viewModel.sendError as? SendFlowError {
                            Text(errorMessage.description)
                                .font(.Main.fixed(.monoRegular, size: 16))
                                .foregroundColor(Color(red: 255/255, green: 82/255, blue: 82/255))
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        if let errorMessage = viewModel.sendError as? NodeError {
                            Text(errorMessage.description)
                                .font(.Main.fixed(.monoRegular, size: 16))
                                .foregroundColor(Color(red: 255/255, green: 82/255, blue: 82/255))
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        
                        PButton(config: .onlyLabel(viewModel.sendError == nil ? "Send" : "Try again"), style: .filled, size: .big, enabled: viewModel.amountIsValid) {
                            viewModel.authenticateUser { authentificated in
                                if authentificated {
                                    withAnimation {
                                        step = .signing
                                    }
                                    viewModel.send { success in
                                        withAnimation {
                                            step = success ? .sent : .reviewing
                                        }
                                    }
                                }
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .padding(16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                case .signing:
                    HStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Signing transaction...")
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(Palette.grayScaleF4)
                    }
                    .frame(height: 60)
                case .sent:
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(Color.green)
                        Text("Signed!")
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(Palette.grayScaleF4)
                    }
                    .frame(height: 60)
                }
            }
            .background(
                Palette.grayScale2A.edgesIgnoringSafeArea(.bottom)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(1)
        }
        .interactiveDismissDisabled(step == .signing)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .onReceive(
            viewModel
                .$unconfirmedTx
                .compactMap{$0}
                .delay(for: 1, scheduler: RunLoop.main)
        ) { transaction in
            guard let coin = viewModel.coin else { return }
            navigation.push(.transactionDetails(coin: coin, tx: transaction))
        }
        //TxFeesPickerView
        .popup(isPresented: $viewModel.showFeesPicker) {
            if let fees = viewModel.recomendedFees, let coin = viewModel.coin {
                TxFeesPickerView(
                    coin: coin,
                    recommendedFees: fees,
                    feeRate: $viewModel.feeRate,
                    onDismiss: {
                        viewModel.showFeesPicker.toggle()
                    }
                )
            } else {
                EmptyView()
            }
        } customize: {
            $0.type(.toast)
              .position(.bottom)
              .animation(.spring())
              .closeOnTap(false)
              .closeOnTapOutside(false)
              .backgroundColor(.black.opacity(0.5))
        }
        //Amount view
        .popup(isPresented: $editingAmount) {
            if let exchanger = viewModel.exchanger {
                AmountEditorView(title: "Edit Amount", exchanger: exchanger) {
                    editingAmount.toggle()
                } onSaveAction: { 
                    editingAmount.toggle()
                }
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .padding(.bottom, 32)
            } else {
                EmptyView()
            }
        } customize: {
            $0.type(.toast)
              .position(.bottom)
              .closeOnTap(false)
              .closeOnTapOutside(false)
              .backgroundColor(.black.opacity(0.5))
        }
    }
}

struct ReviewTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.walletManager.register { WalletManager.mocked }
        let _ = Container.adapterManager.register { AdapterManager.mocked }
        
        ReviewTransactionView(viewModel: SendViewViewModel.mocked)
    }
}
