//
//  RecoveryPhraseView.swift
//  Portal
//
//  Created by farid on 11/28/22.
//

import SwiftUI
import PortalUI

struct RecoveryPhraseView: View {
    @EnvironmentObject private var navigation: NavigationStack
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewModel: RecoveryPhraseViewModel
    
    init(viewModel: RecoveryPhraseViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack {
                    PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                        navigation.pop()
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
                            WordView(index: index, word: viewModel.recoveryPhrase[index - 1])
                        }
                    }
                    
                    VStack(spacing: 10) {
                        ForEach((viewModel.recoveryPhrase.count/2 + 1...viewModel.recoveryPhrase.count), id: \.self) { index in
                            WordView(index: index, word: viewModel.recoveryPhrase[index - 1])
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
                        navigation.push(.recoveryPhraseTest(viewModel: viewModel))
                    }
                }
                .padding(16)
            }
            .background(
                Palette.grayScale2A.edgesIgnoringSafeArea(.bottom)
            )
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
    }
}

struct RecoveryPhraseView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPhraseView(
            viewModel: RecoveryPhraseViewModel(
                storage: LocalStorage.mocked, recoveryPhrase: [
                    "point", "head", "pencil", "differ", "reopen", "damp", "wink", "minute", "improve", "toward", "during", "term"
                ]
            )
        )
    }
}
