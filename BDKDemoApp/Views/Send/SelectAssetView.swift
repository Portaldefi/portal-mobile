//
//  SelectAssetView.swift
//  BDKDemoApp
//
//  Created by farid on 7/25/22.
//

import SwiftUI
import Combine
import PortalUI
import Factory

struct SelectAssetView: View {
    @Binding var item: QRCodeItem?
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewModel = Container.sendViewModel()
    @State private var notEnoughFunds = false
    @State private var notEnoughFundsMessage = String()
    
    init(qrItem: Binding<QRCodeItem?>) {
        self._item = qrItem
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    PButton(
                        config: .onlyIcon(Asset.xIcon),
                        style: .free,
                        size: .medium,
                        enabled: true
                    ) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(width: 20)
                    
                    Spacer()
                }
                
                Text("Send")
                    .font(.Main.fixed(.bold, size: 16))
                    .foregroundColor(Palette.grayScaleCA)
                    .frame(height: 62)
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
                                    WalletItemView(item: item)
                                        .if(item.viewModel.balance == 0) { itemView in
                                            itemView.opacity(0.4)
                                        }
                                        .padding(.leading)
                                        .padding(.trailing, 6)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            guard item.viewModel.balance > 0 else {
                                                notEnoughFundsMessage = "\(item.viewModel.coin.code) on \(item.viewModel.coin.description)"
                                                return notEnoughFunds.toggle()
                                            }
                                            viewModel.selectedItem = item
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
                
                NavigationLink(
                    destination: SendView(),
                    isActive: $viewModel.goToSend
                ) {
                    EmptyView()
                }
            }
        }
        .padding(.horizontal, 16)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .navigationBarHidden(true)
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
        SelectAssetView(qrItem: .constant(nil))
            .environmentObject(AccountViewModel.mocked)
    }
}
