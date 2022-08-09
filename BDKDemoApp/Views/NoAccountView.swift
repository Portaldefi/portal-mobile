//
//  NoAccountView.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import SwiftUI
import PortalUI

struct NoAccountView: View {
    @State private var createAccount: Bool = false
    @State private var restoreAccount: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 26/255, green: 26/255, blue: 26/255, opacity: 1).ignoresSafeArea()
                
                VStack {
                    Text("Welcome to Portal")
                        .foregroundColor(.white)
                        .font(.system(size: 16, design: .monospaced))
                        .fontWeight(.bold)
                    Spacer()
                    PButton(config: .onlyLabel("Create account"), style: .filled, size: .medium, enabled: true) {
                        createAccount.toggle()
                    }
                    PButton(config: .onlyLabel("Restore account"), style: .filled, size: .medium, enabled: true) {
                        restoreAccount.toggle()
                    }
                    NavigationLink(destination: CreateAccountView(), isActive: $createAccount) { EmptyView() }
                    NavigationLink(destination: RestoreAccountView(), isActive: $restoreAccount) { EmptyView() }
                }
                .padding()
                .navigationBarHidden(true)
            }
        }
    }
}

struct NoWalletView_Previews: PreviewProvider {
    static var previews: some View {
        NoAccountView()
    }
}
