//
//  ReceiveSelectAssetView.swift
//  Portal
//
//  Created by farid on 2/7/23.
//

import SwiftUI
import PortalUI

struct ReceiveSelectAssetView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var navigation: NavigationStack
    @ObservedObject var viewModel: ReceiveViewModel
            
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
                
                Text("Receive")
                    .frame(width: 300, height: 62)
                    .font(.Main.fixed(.monoBold, size: 16))
            }
            .padding(.horizontal, 10)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Asset")
                    .font(.Main.fixed(.bold, size: 24))
                    .foregroundColor(Palette.grayScaleCA)
                    .padding(.horizontal, 8)
                
                ScrollView {
                    VStack {
                        VStack(spacing: 0) {
                            ForEach(viewModel.walletItems) { item in
                                ZStack(alignment: .trailing) {
                                    WalletItemView(viewModel: item.viewModel)
                                        .padding(.leading, 16)
                                        .padding(.trailing, 14)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            viewModel.selectedItem = item
                                            navigation.push(.receiveGenerateQRCode(viewModel: viewModel))
                                        }
                                                                        
                                    Asset.chevronRightIcon
                                        .foregroundColor(Palette.grayScale4A)
                                }
                                
                                Divider()
                                    .frame(height: 1)
                                    .overlay(Palette.grayScale2A)
                            }
                        }
                    }
                }
                .frame(height: CGFloat(viewModel.walletItems.count) * 72)
            }
        }
        .padding(.horizontal, 8)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
    }
}


struct ReceiveSelectAssetView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiveSelectAssetView(viewModel: ReceiveViewModel.mocked)
    }
}

