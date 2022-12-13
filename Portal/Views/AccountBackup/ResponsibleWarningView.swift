//
//  ResponsibleWarningView.swift
//  Portal
//
//  Created by farid on 11/30/22.
//

import SwiftUI
import PortalUI
import Factory

struct ResponsibleWarningView: View {
    @EnvironmentObject private var navigation: NavigationStack
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
                        viewModel.isCorrectSelection = true
                        navigation.pop()
                    }
                    .frame(width: 20)
                    
                    Spacer()
                }
                .animation(nil, value: false)
                
                Text("You’re the only one responsible")
                    .multilineTextAlignment(.center)
                    .font(.Main.fixed(.monoBold, size: 26))
                    .foregroundColor(Palette.grayScaleCA)
                    .padding(.top, 22)
                
                Text("If you lose this device you’ll\nneed your Recovery Phrase to\nrecover your account\n\nPortal doesn’t store it, so it can not help you recover your account\nif you lose your device or Recovery Phrase")
                    .multilineTextAlignment(.leading)
                    .font(.Main.fixed(.monoRegular, size: 16))
                    .foregroundColor(Palette.grayScale8A)
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                Divider()
                    .frame(height: 1)
                    .overlay(Palette.grayScale4A)
                
                HStack {
                    PButton(config: .onlyLabel("I have baсked up"), style: .filled, size: .big, enabled: true) {
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

struct ResponsibleWarningView_Previews: PreviewProvider {
    static var previews: some View {
        ResponsibleWarningView(viewModel: RecoveryPhraseViewModel(
            storage: LocalStorage.mocked,
            recoveryPhrase: ["point", "head", "pencil", "differ", "reopen", "damp", "wink", "minute", "improve", "toward", "during", "term"]
        ))
    }
}
