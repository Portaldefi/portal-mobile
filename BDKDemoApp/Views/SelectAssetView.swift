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
        self._item = qrItem
    }
        
    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 10/255).ignoresSafeArea()
            
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
                        .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255))
                        .frame(height: 62)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Asset")
                            .font(.Main.fixed(.bold, size: 24))
                            .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255))

                        ScrollView {
                            VStack {
                                VStack(spacing: 0) {
                                    Divider()
                                    ForEach(viewModel.walletItems) { item in
                                        WalletItemView(item: item)
                                            .padding(.horizontal)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                viewModel.selectedItem = item
                                            }
                                        Divider()
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
