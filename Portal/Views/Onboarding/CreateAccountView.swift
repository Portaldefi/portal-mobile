//
//  CreateAccountView.swift
// Portal
//
//  Created by farid on 8/9/22.
//

import SwiftUI
import PortalUI

struct CreateAccountView: View {
    @FocusState private var isFocused: Bool
    @ObservedObject private var viewModel: CreateAccountViewModel
    @EnvironmentObject private var navigation: NavigationStack
    
    init(words: [String]? = nil) {
        UITableView.appearance().backgroundColor = .clear

        if let words = words {
            viewModel = CreateAccountViewModel(words: words)
        } else {
            viewModel = CreateAccountViewModel()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                HStack {
                    PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                        navigation.pop()
                    }
                    .frame(width: 20)
                    
                    Spacer()
                }
                
                Text("Name your portfolio")
                    .font(.Main.fixed(.monoBold, size: 16))
            }
            .frame(height: 62)
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("Portfolio name", text: $viewModel.accountName)
                    .focused($isFocused)
                    .disableAutocorrection(true)
                    .font(viewModel.accountName.isEmpty ? .Main.fixed(.monoRegular, size: 16) : .Main.fixed(.monoBold, size: 16))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Palette.grayScale3A, lineWidth: 1)
                            .frame(height: 60)
                    )
                
                Text("You can change this later")
                    .font(.Main.fixed(.monoRegular, size: 14))
                    .foregroundColor(Palette.grayScale6A)
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 0) {
                HStack {
                    Asset.helpIcon
                        .foregroundColor(Palette.grayScale8A)
                    
                    Text("Portfolios are wallets that can\nstore multiple assets.")
                        .font(.Main.fixed(.monoRegular, size: 14))
                        .foregroundColor(Palette.grayScale8A)
                    
                    Spacer()
                }
                .frame(height: 86)
                .padding(.horizontal, 16)
                
                VStack(spacing: 0) {
                    Divider()
                        .frame(height: 1)
                        .overlay(Palette.grayScale4A)
                    
                    PButton(config: .onlyLabel("Continue"), style: .filled, size: .big, enabled: !viewModel.accountName.isEmpty) {
                        withAnimation {
                            viewModel.createAccount()
                        }
                    }
                    .padding(16)
                }
                .background(
                    Palette.grayScale2A.edgesIgnoringSafeArea(.bottom)
                )
            }
        }
        .navigationBarHidden(true)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .onAppear {
            isFocused = true
        }
    }
}

struct CreateWalletView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView()
    }
}
