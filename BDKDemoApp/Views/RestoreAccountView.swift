//
//  RestoreAccountView.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import SwiftUI
import PortalUI

struct RestoreAccountView: View {
    @ObservedObject private var viewModel = RestoreAccountViewModel()
    
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
                        TextField("Enter seed phrase...", text: $viewModel.seed)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)
                            .foregroundColor(.white)
                            .font(.system(size: 14, design: .monospaced))
                    }
                }
                
                Spacer()
                
                PButton(config: .onlyLabel("Restore account"), style: .filled, size: .medium, enabled: viewModel.restorable) {
                    viewModel.restoreAccount()
                }
                .padding()
            }
        }
        .navigationTitle("Restore Account")
        .modifier(BackButtonModifier())
    }
}

struct RestoreAccountView_Previews: PreviewProvider {
    static var previews: some View {
        RestoreAccountView()
    }
}
