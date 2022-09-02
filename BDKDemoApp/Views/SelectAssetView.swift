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
    
    init(qrItem: Binding<QRCodeItem?>) {
        UITableView.appearance().backgroundColor = .clear
        self._item = qrItem
    }
    
    private func AssetItemView(item: WalletItem) -> some View {
        ZStack {
            Color(red: 26/255, green: 26/255, blue: 26/255)
            
            WalletItemView(item: item)
                .padding(.horizontal)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectedItem = item
                }
        }
        .if(viewModel.walletItems.count == 1) { zStack in
            zStack
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 42/255, green: 42/255, blue: 42/255), lineWidth: 1)
                )
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 10/255).ignoresSafeArea()
            
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
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .frame(height: 62)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Asset")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                        
                        ScrollView {
                            VStack {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.walletItems) { item in
                                        AssetItemView(item: item)
                                        
                                        if viewModel.walletItems.count > 1 {
                                            Divider()
                                        }
                                    }
                                }
                                .if(viewModel.walletItems.count > 1) { vStack in
                                    vStack
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(red: 42/255, green: 42/255, blue: 42/255), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .frame(height: CGFloat(viewModel.walletItems.count) * 68)
                        
                        NavigationLink(
                            destination: SendView(),
                            isActive: $viewModel.goToSend
                        ) {
                            EmptyView()
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .navigationBarHidden(true)
    }
}

struct SendFromView_Previews: PreviewProvider {
    static var previews: some View {
        SelectAssetView(qrItem: .constant(nil))
            .environmentObject(AccountViewModel.mocked())
    }
}
