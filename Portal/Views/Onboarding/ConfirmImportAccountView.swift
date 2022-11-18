//
//  ConfirmImportAccountView.swift
//  Portal
//
//  Created by farid on 11/18/22.
//

import SwiftUI
import PortalUI

struct ConfirmImportAccountView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var viewModel: RestoreAccountViewModel
    @State private var goToCreate = false
    
    var body: some View {
        NavigationLink(
            destination: CreateAccountView(words: viewModel.input.components(separatedBy: " ").filter{ !$0.isEmpty && $0.count >= 3 }),
            isActive: $goToCreate
        ) { EmptyView() }
        
        VStack(alignment: .leading, spacing: 10) {
            Text("We detected seed phrase")
                .font(.Main.fixed(.monoBold, size: 24))
                .foregroundColor(Palette.grayScaleCA)
            Text("Is this what you wanted?")
                .font(.Main.fixed(.monoBold, size: 20))
                .foregroundColor(Palette.grayScale8A)
            Spacer()
            
            PButton(config: .onlyLabel("Yes, import"), style: .filled, size: .big, enabled: true) {
                withAnimation {
                    goToCreate.toggle()
                }
            }
            
            PButton(config: .onlyLabel("No, go back"), style: .free, size: .big, enabled: true) {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .padding(.top, 108)
        .padding(.bottom, 87)
        .padding(.horizontal)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .navigationBarHidden(true)
    }
}

struct ConfirmImportAccountView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmImportAccountView(viewModel: RestoreAccountViewModel())
    }
}
