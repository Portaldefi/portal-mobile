//
//  ReviewTransactionView.swift
//  BDKDemoApp
//
//  Created by farid on 26/8/22.
//

import SwiftUI
import PortalUI
import Factory

struct ReviewTransactionView: View {
    @State private var isAuthorizated = false
    @FocusState private var isFocused: Bool
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewModel: SendViewViewModel = Container.sendViewModel()
    
    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 10/255).ignoresSafeArea()
            
            NavigationLink(
                destination: ConfirmationView(),
                isActive: $viewModel.txSent
            ) {
                EmptyView()
            }
            
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        PButton(config: .onlyIcon(Asset.arrowLeftIcon), style: .free, size: .small, enabled: true) {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .frame(width: 20)
                        
                        Spacer()
                    }
                    
                    Text("Review Transaction")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .frame(height: 62)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let item = viewModel.selectedItem {
                            Text("From")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                            
                            WalletItemView(item: item)
                                .padding(.horizontal)
                                .contentShape(Rectangle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 42/255, green: 42/255, blue: 42/255), lineWidth: 1)
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                        
                        ZStack {
                            HStack(alignment: .bottom) {
                                Text(viewModel.amount)
                                    .font(Font.system(size: 24, weight: .bold, design: .monospaced))
                                Text("btc")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255))
                                    .offset(y: -2)
                                Spacer()
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        Color(red: 26/255, green: 26/255, blue: 26/255)
                                    )
                            )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recipient")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                        
                        ZStack {
                            HStack {
                                Text(viewModel.to)
                                    .focused($isFocused)
                                    .font(Font.system(size: 16, weight: .bold, design: .monospaced))
                            }
                            .padding()
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    Color(red: 26/255, green: 26/255, blue: 26/255)
                                )
                        )
                        
                        HStack {
                            PButton(config: .labelAndIconLeft(label: "Annotate", icon: Asset.pencilIcon), style: .free, size: .small, enabled: false) {
                                
                            }
                            PButton(config: .labelAndIconLeft(label: "Tag", icon: Asset.tagIcon), style: .free, size: .small, enabled: false) {
                                
                            }
                        }
                        .padding()
                    }
                    
                    if !isAuthorizated {
                        Button {
                            isAuthorizated = true
                            viewModel.authenticateUser { success in
                                isAuthorizated = false
                                guard success else { return }
                                viewModel.send()
                            }
                        } label: {
                            Text("Send")
                                .foregroundColor(.black)
                                .font(.system(size: 22, design: .monospaced))
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(Color.blue)
                                .background(in: RoundedRectangle(cornerRadius: 10))
                                .frame(height: 60)
                        }
                        .disabled(!viewModel.sendButtonEnabled)
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused = false
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .navigationBarHidden(true)
    }
}

struct ReviewTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        ReviewTransactionView()
    }
}
