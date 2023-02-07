//
//  SelectAssetView.swift
// Portal
//
//  Created by farid on 7/25/22.
//

import SwiftUI
import Combine
import PortalUI
import Factory

struct SendSelectAssetView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var navigation: NavigationStack
    @ObservedObject var viewModel: SendViewViewModel
    @State private var notEnoughFunds = false
    @State private var notEnoughFundsMessage = String()
            
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    PButton(config: .onlyIcon(Asset.xIcon), style: .free, size: .medium, enabled: true) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(width: 20)
                    
                    Spacer()
                }
                
                Text("Send")
                    .frame(width: 300, height: 62)
                    .font(.Main.fixed(.monoBold, size: 16))
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Asset")
                    .font(.Main.fixed(.bold, size: 24))
                    .foregroundColor(Palette.grayScaleCA)
                
                ScrollView {
                    VStack {
                        VStack(spacing: 0) {
                            Divider()
                            ForEach(viewModel.walletItems) { item in
                                ZStack(alignment: .trailing) {
                                    WalletItemView(viewModel: item.viewModel)
                                        .padding(.leading)
                                        .padding(.trailing, 6)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            guard item.viewModel.balance > 0 else {
                                                notEnoughFundsMessage = "\(item.viewModel.coin.code) on \(item.viewModel.coin.description)"
                                                return notEnoughFunds.toggle()
                                            }
                                            viewModel.coin = item.viewModel.coin
                                            navigation.push(.sendSetRecipient(viewModel: viewModel))
                                        }
                                    Asset.chevronRightIcon
                                        .foregroundColor(Palette.grayScale4A)
                                }
                                
                                Divider()
                                    .overlay(Palette.grayScale2A)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(viewModel.walletItems.count) * 72)
            }
        }
        .padding(.horizontal, 16)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .alert(isPresented: $notEnoughFunds) {
            Alert(title: Text("Not Enough Funds"),
                  message: Text("Your wallet doesn’t have \(notEnoughFundsMessage) to start this transfer."),
                  dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct SendFromView_Previews: PreviewProvider {
    static var previews: some View {
        SendSelectAssetView(viewModel: SendViewViewModel.mocked)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
