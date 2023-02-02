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

struct ReviewTransactionView: View {
    @FocusState private var isFocused: Bool
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewModel: SendViewViewModel
    @EnvironmentObject private var navigation: NavigationStack
    
    init(viewModel: SendViewViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
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
            
            Button {
                withAnimation {
                    viewModel.editingAmount.toggle()
                }
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
            
            Divider()
            
            Spacer()
        }
        .onReceive(viewModel.$txSent) { sent in
            guard let coin = viewModel.coin else { return }
            if sent {
                navigation.push(.transactionDetails(coin: coin, tx: viewModel.unconfirmedTx != nil ? viewModel.unconfirmedTx! : TransactionRecord.mocked))
            }
        }
    }
}

struct ReviewTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewTransactionView(viewModel: SendViewViewModel.mocked)
            .padding(.top, 40)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
