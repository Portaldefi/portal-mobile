//
//  NoAccountView.swift
// Portal
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
            VStack {
                VStack(spacing: 51) {
                    Asset.portalIcon
                    Text("Your Gateway To\nUncensorable Finance")
                        .foregroundColor(Palette.grayScaleCA)
                        .font(.Main.fixed(.monoBold, size: 21))
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 144)
                Spacer()
                PButton(config: .onlyLabel("Create Wallet"), style: .filled, size: .big, enabled: true) {
                    createAccount.toggle()
                }
                PButton(config: .onlyLabel("Import Wallet"), style: .outline, size: .big, enabled: true) {
                    restoreAccount.toggle()
                }
                NavigationLink(destination: CreateAccountView(), isActive: $createAccount) { EmptyView() }
                NavigationLink(destination: RestoreAccountView(), isActive: $restoreAccount) { EmptyView() }
            }
            .padding(.bottom, 87)
            .padding(.horizontal)
            .navigationBarHidden(true)
            .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        }
    }
}

struct NoWalletView_Previews: PreviewProvider {
    static var previews: some View {
        NoAccountView()
    }
}
