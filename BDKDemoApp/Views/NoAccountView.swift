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
                Color(red: 10/255, green: 10/255, blue: 10/255, opacity: 1).ignoresSafeArea()
                
                VStack {
                    VStack(spacing: 51) {
                        Asset.portalLogo
                        Text("Your Gateway To\nUncensorable Finance")
                            .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255, opacity: 1))
                            .font(.system(size: 21, design: .monospaced))
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 144)
                    Spacer()
                    PButton(config: .onlyLabel("Create account"), style: .filled, size: .big, enabled: true) {
                        createAccount.toggle()
                    }
                    PButton(config: .onlyLabel("Restore account"), style: .outline, size: .big, enabled: true) {
                        restoreAccount.toggle()
                    }
                    NavigationLink(destination: CreateAccountView(), isActive: $createAccount) { EmptyView() }
                    NavigationLink(destination: RestoreAccountView(), isActive: $restoreAccount) { EmptyView() }
                }
                .padding(.bottom, 87)
                .padding(.horizontal)
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
