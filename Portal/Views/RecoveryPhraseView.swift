//
//  RecoveryPhraseView.swift
//  Portal
//
//  Created by farid on 11/28/22.
//

import SwiftUI
import PortalUI

struct RecoveryPhraseView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var viewModel: RecoveryPhraseViewModel
    
    init(viewModel: RecoveryPhraseViewModel = RecoveryPhraseViewModel.config()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack {
                    PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(width: 20)
                    
                    Spacer()
                }
                .animation(nil, value: false)
                
                Text("This is your recovery phrase")
                    .multilineTextAlignment(.center)
                    .font(.Main.fixed(.monoBold, size: 26))
                    .foregroundColor(Palette.grayScaleCA)
                    .padding(.top, 22)
                
                Text("Write down these 12 words in the right order. You have to verify this later.")
                    .multilineTextAlignment(.leading)
                    .font(.Main.fixed(.monoRegular, size: 16))
                    .foregroundColor(Palette.grayScale8A)
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                
                //TODO: - Rework with grid in iOS16
                HStack(spacing: 15) {
                    VStack(spacing: 10) {
                        ForEach((1...viewModel.recoveryPhrase.count/2), id: \.self) { index in
                            ClickableWordView(index: index, word: viewModel.recoveryPhrase[index - 1])
                        }
                    }
                    
                    VStack(spacing: 10) {
                        ForEach((viewModel.recoveryPhrase.count/2 + 1...viewModel.recoveryPhrase.count), id: \.self) { index in
                            ClickableWordView(index: index, word: viewModel.recoveryPhrase[index - 1])
                        }
                    }
                }
                .padding(.top, 16)
                                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                Divider()
                    .frame(height: 1)
                    .overlay(Palette.grayScale4A)
                
                HStack {
                    PButton(config: .onlyLabel("Verify"), style: .filled, size: .big, enabled: true) {
                        
                    }
                }
                .padding(16)
            }
            .background(
                Palette.grayScale2A.edgesIgnoringSafeArea(.bottom)
            )
        }
        .navigationBarHidden(true)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
    }
}

struct RecoveryPhraseView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPhraseView(
            viewModel: RecoveryPhraseViewModel(
                recoveryPhrase: [
                    "point", "head", "pencil", "differ", "reopen", "damp", "wink", "minute", "improve", "toward", "during", "term"
                ]
            )
        )
    }
}
