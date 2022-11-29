//
//  BackUpDetailsView.swift
//  Portal
//
//  Created by farid on 11/28/22.
//

import SwiftUI
import PortalUI

struct BackUpDetailsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: RecoveryPhraseViewModel = RecoveryPhraseViewModel.config()
    @State private var showRecoveryPhrase = false

    var body: some View {
        ZStack(alignment: .bottom) {
            
            NavigationLink(
                destination: RecoveryPhraseView(viewModel: viewModel),
                isActive: $showRecoveryPhrase
            ) {
                EmptyView()
            }

            VStack(spacing: 0) {
                HStack {
                    PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(width: 20)
                    
                    Spacer()
                }
                .animation(nil, value: false)
                
                Text("Keep funds safe by backing up your recovery phrase")
                    .multilineTextAlignment(.center)
                    .font(.Main.fixed(.monoBold, size: 26))
                    .foregroundColor(Palette.grayScaleCA)
                    .padding(.top, 22)
                
                Text("A recovery phrase is a series of 12 words in a specific order. This word combination is unique to your wallet.\n\nMake sure to have pen and paper ready so you can write it down.")
                    .multilineTextAlignment(.leading)
                    .font(.Main.fixed(.monoRegular, size: 16))
                    .foregroundColor(Palette.grayScale8A)
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 16) {
                PButton(config: .onlyLabel("Do this later"), style: .free, size: .medium, applyGradient: true, enabled: true) {
                    presentationMode.wrappedValue.dismiss()
                }
                
                VStack(spacing: 0) {
                    Divider()
                        .frame(height: 1)
                        .overlay(Palette.grayScale4A)
                    
                    HStack {
                        PButton(config: .onlyLabel("Continue"), style: .filled, size: .big, enabled: true) {
                            showRecoveryPhrase.toggle()
                        }
                    }
                    .padding(16)
                }
                .background(
                    Palette.grayScale2A.edgesIgnoringSafeArea(.bottom)
                )
            }
        }
        .navigationBarHidden(true)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
    }
}

struct BackUpDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        BackUpDetailsView()
    }
}
