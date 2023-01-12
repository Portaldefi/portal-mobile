//
//  ConfirmImportAccountView.swift
//  Portal
//
//  Created by farid on 11/18/22.
//

import SwiftUI
import PortalUI

struct ConfirmImportAccountView: View {
    @EnvironmentObject private var navigation: NavigationStack
    @ObservedObject var viewModel: RestoreAccountViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("We detected seed phrase")
                .font(.Main.fixed(.monoBold, size: 24))
                .foregroundColor(Palette.grayScaleCA)
            Text("Is this what you wanted?")
                .font(.Main.fixed(.monoBold, size: 20))
                .foregroundColor(Palette.grayScale8A)
            Spacer()
            
            PButton(config: .onlyLabel("Yes, import"), style: .filled, size: .big, enabled: true) {
                navigation.push(.nameAccount(words: viewModel.words))
            }
            
            PButton(config: .onlyLabel("No, go back"), style: .free, size: .big, enabled: true) {
                navigation.pop()
            }
        }
        .padding(.top, 108)
        .padding(.bottom, 87)
        .padding(.horizontal)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
    }
}

struct ConfirmImportAccountView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmImportAccountView(viewModel: RestoreAccountViewModel())
    }
}
