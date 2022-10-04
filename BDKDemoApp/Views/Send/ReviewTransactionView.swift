//
//  ReviewTransactionView.swift
//  BDKDemoApp
//
//  Created by farid on 26/8/22.
//

import SwiftUI
import PortalUI
import Factory
import BitcoinDevKit

struct ReviewTransactionView: View {
    @State private var isAuthorizated = false
    @FocusState private var isFocused: Bool
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewModel: SendViewViewModel = Container.sendViewModel()
    
    var body: some View {
        NavigationLink(
            destination: TransactionDetailsView(coin: .bitcoin(), tx: BitcoinDevKit.Transaction.mockedConfirmed),
            isActive: $viewModel.txSent
        ) {
            EmptyView()
        }
        
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Text("Recipient")
                    .font(.Main.fixed(.monoBold, size: 14))
                    .foregroundColor(Palette.grayScaleAA)

                Text(viewModel.to)
                    .font(.Main.fixed(.monoRegular, size: 16))
                    .foregroundColor(Palette.grayScaleF4)
            }
            .padding(.vertical, 16)
            
            Divider()
            
            HStack(alignment: .top, spacing: 16) {
                Text("Amount")
                    .font(.Main.fixed(.monoBold, size: 14))
                    .foregroundColor(Palette.grayScaleAA)
                
                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(viewModel.exchanger.cryptoAmount)
                            .font(.Main.fixed(.monoBold, size: 32))
                            .foregroundColor(Palette.grayScaleEA)
                            .frame(height: 26)
                        
                        Text("btc")
                            .font(.Main.fixed(.monoRegular, size: 18))
                            .foregroundColor(Palette.grayScale6A)
                    }
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(viewModel.exchanger.currencyAmount)
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Palette.grayScale6A)
                        
                        Text("usd")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Palette.grayScale6A)
                    }
                }
            }
            .padding(.vertical, 16)

            Divider()
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fees")
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(Palette.grayScaleAA)
                    Text("Fast ~ 10-20 mins")
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(Color(red: 0.191, green: 0.858, blue: 0.418))
                }
                
                Spacer()
                
                if let fee = viewModel.fee {
                    VStack {
                        HStack(spacing: 4) {
                            Text(fee)
                                .font(.Main.fixed(.monoBold, size: 16))
                                .foregroundColor(Palette.grayScaleEA)

                            Text("sat/vByte")
                                .font(.Main.fixed(.monoMedium, size: 11))
                                .foregroundColor(Palette.grayScale6A)
                                .frame(width: 34)
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
        .padding(.horizontal, 16)
        .navigationBarHidden(true)
    }
}

struct ReviewTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewTransactionView()
    }
}
