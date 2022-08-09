//
//  CreateAccountView.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import SwiftUI
import PortalUI

struct CreateAccountView: View {
    @ObservedObject private var viewModel = CreateAccountViewModel()
    
    init() {
        UITableView.appearance().backgroundColor = .clear
    }
    
    var body: some View {
        ZStack {
            Color(red: 26/255, green: 26/255, blue: 26/255, opacity: 1).ignoresSafeArea()
            
            VStack {
                Form {
                    Section(header: Text("Account name").textStyle(BasicTextStyle(white: true))) {
                        TextField("Name", text: $viewModel.accountName)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                    }
                    
                    Section(header: Text("SEED").textStyle(BasicTextStyle(white: true))) {
                        Text(viewModel.extendedKey.mnemonic)
                            .foregroundColor(.white)
                            .font(.system(size: 14, design: .monospaced))
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                PButton(config: .onlyLabel("Create account"), style: .filled, size: .medium, enabled: !viewModel.accountName.isEmpty) {
                    viewModel.createAccount()
                }
                .padding()
            }
        }
        .navigationTitle("Create Account")
        .modifier(BackButtonModifier())
    }
}

struct CreateWalletView_Previews: PreviewProvider {
    static var previews: some View {
        CreateAccountView()
    }
}
