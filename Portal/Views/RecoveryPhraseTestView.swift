//
//  RecoveryPhraseTestView.swift
//  Portal
//
//  Created by farid on 11/29/22.
//

import SwiftUI
import PortalUI
import Factory

struct RecoveryPhraseTestView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewModel: RecoveryPhraseViewModel
    @ObservedObject private var viewState: ViewState = Container.viewState()
    
    init(viewModel: RecoveryPhraseViewModel) {
        self.viewModel = viewModel
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
                
                Text("Tap the words in the correct order")
                    .multilineTextAlignment(.center)
                    .font(.Main.fixed(.monoBold, size: 26))
                    .foregroundColor(Palette.grayScaleCA)
                    .padding(.top, 22)
                
                Spacer()
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
                                viewModel.select(word: viewModel.recoveryTest[index - 1])
                            }
                        }
                    }
                    
                    VStack(spacing: 10) {
                        ForEach((viewModel.recoveryTest.count/2 + 1...viewModel.recoveryPhrase.count), id: \.self) { index in
                            
                            let word = viewModel.recoveryTest[index - 1]
                            let displayIndex = viewModel.indexOf(word: word)
                            let isCorrectSelection = viewModel.isCorrectSelection(word: word)
                            
                            ClickableWordView(index: displayIndex, word: word, isCorrectSelection: isCorrectSelection) {
                                viewModel.select(word: viewModel.recoveryTest[index - 1])
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
                        viewModel.markAccountAsBackedUp()
                        viewState.goToBackUp.toggle()
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
