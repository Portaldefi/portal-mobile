//
//  SetSecuritySettingsView.swift
//  Portal
//
//  Created by farid on 24.06.2023.
//

import SwiftUI
import PortalUI

struct SetSecuritySettingsView: View {
    @ObservedObject var viewModel: CreateAccountViewModel
    
    var body: some View {
        ZStack(alignment: .bottom) {
            SecuritySettingsView(canGoBack: true)
            
            VStack(spacing: 0) {
                Divider()
                    .frame(height: 1)
                    .overlay(Palette.grayScale4A)
                
                PButton(config: .onlyLabel("Continue"), style: .filled, size: .big, enabled: true) {
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
}

struct SetSecuritySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SetSecuritySettingsView(viewModel: CreateAccountViewModel())
    }
}
