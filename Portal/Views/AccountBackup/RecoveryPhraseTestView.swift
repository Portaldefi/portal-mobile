//
//  RecoveryPhraseTestView.swift
//  Portal
//
//  Created by farid on 11/29/22.
//

import SwiftUI
import PortalUI

struct RecoveryPhraseTestView: View {
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
                        viewModel.isCorrectSelection = true
                        navigation.pop()
                    }
                    .frame(width: 20)
                    
                    Spacer()
                }
                .animation(nil, value: false)
                
                Text("Tap the words in the correct order")
                    .multilineTextAlignment(.center)
                    .font(.Main.fixed(.monoBold, size: 26))
                    .foregroundColor(Palette.grayScaleCA)
                    .padding(.top, 22)
                
                HStack {
                    if !viewModel.isCorrectSelection {
                        Text("Not the next word, try again")
                            .font(.Main.fixed(.monoRegular, size: 16))
                            .foregroundColor(.red)
                    } else {
                        Text(viewModel.testPassed ? "Correct!" : " ")
                            .font(.Main.fixed(.monoRegular, size: 16))
                            .foregroundColor(.green)
                    }
                }
                .frame(height: 66)
                .padding(.horizontal, 16)
                
                //TODO: - Rework with grid in iOS16
                HStack(spacing: 15) {
                    VStack(spacing: 10) {
                        ForEach((1...viewModel.recoveryTest.count/2), id: \.self) { index in
                            let word = viewModel.recoveryTest[index - 1]
                            let displayIndex = viewModel.indexOf(word: word)
                            let isCorrectSelection = viewModel.isCorrectSelection(word: word)
                            
                            ClickableWordView(index: displayIndex, word: word, isCorrectSelection: isCorrectSelection) {
                                viewModel.select(word: word)
                            }
                        }
                    }
                    
                    VStack(spacing: 10) {
                        ForEach((viewModel.recoveryTest.count/2 + 1...viewModel.recoveryPhrase.count), id: \.self) { index in
                            
                            let word = viewModel.recoveryTest[index - 1]
                            let displayIndex = viewModel.indexOf(word: word)
                            let isCorrectSelection = viewModel.isCorrectSelection(word: word)
                            
                            ClickableWordView(index: displayIndex, word: word, isCorrectSelection: isCorrectSelection) {
                                viewModel.select(word: word)
                            }
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
                    PButton(config: .onlyLabel("Continue"), style: .filled, size: .big, enabled: viewModel.testPassed) {
                        navigation.push(.recoveryWarning(viewModel: viewModel))
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

struct RecoveryPhraseTestView_Previews: PreviewProvider {
    static var previews: some View {
        RecoveryPhraseTestView(
            viewModel: RecoveryPhraseViewModel(
                storage: LocalStorage.mocked,
                recoveryPhrase: ["point", "head", "pencil", "differ", "reopen", "damp", "wink", "minute", "improve", "toward", "during", "term"]
            )
        )
    }
}
