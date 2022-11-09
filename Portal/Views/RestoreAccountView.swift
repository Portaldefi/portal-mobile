//
//  RestoreAccountView.swift
// Portal
//
//  Created by farid on 8/9/22.
//

import SwiftUI
import PortalUI

struct RestoreAccountView: View {
    @ObservedObject private var viewModel = RestoreAccountViewModel()
    
    var body: some View {
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
        .navigationTitle("Restore Account")
        .modifier(BackButtonModifier())
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale1A))
    }
}

struct RestoreAccountView_Previews: PreviewProvider {
    static var previews: some View {
        RestoreAccountView()
    }
}
