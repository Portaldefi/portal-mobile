//
//  NoAccountView.swift
// Portal
//
//  Created by farid on 8/9/22.
//

import SwiftUI
import PortalUI

struct NoAccountView: View {
    @EnvironmentObject private var navigation: NavigationStack
    
    var body: some View {
        VStack {
            VStack(spacing: 56) {
                Asset.portalBetaIcon
                Text("Your Gateway To\nUncensorable Apps")
                    .foregroundColor(Palette.grayScaleCA)
                    .font(.Main.fixed(.monoBold, size: 21))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 172)
            Spacer()
            PButton(config: .onlyLabel("Create Wallet"), style: .filled, size: .big, enabled: true) {
                navigation.push(.createAccount)
            }
            PButton(config: .onlyLabel("Import Wallet"), style: .outline, size: .big, enabled: true) {
                navigation.push(.restoreAccount)
            }
        }
        .padding(.bottom, 87)
        .padding(.horizontal)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
    }
}

struct NoWalletView_Previews: PreviewProvider {
    static var previews: some View {
        NoAccountView()
    }
}
