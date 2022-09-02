//
//  ConfirmationView.swift
//  BDKDemoApp
//
//  Created by farid on 9/2/22.
//

import SwiftUI
import PortalUI
import Factory

struct ConfirmationView: View {
    @Environment(\.presentationMode) private var presentationMode
    @Injected(Container.viewState) private var viewState: ViewState
    @ObservedObject private var viewModel: SendViewViewModel = Container.sendViewModel()

    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 10/255).ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        Spacer()
                        PButton(config: .onlyIcon(Asset.xIcon), style: .free, size: .small, enabled: true) {
                            if viewState.showScanner {
                                viewState.showScanner.toggle()
                            } else {
                                viewState.goToSend.toggle()
                            }
                        }
                        .frame(width: 20)
                    }
                    
                    Text(viewModel.sendError != nil ? "Failure" : "Success")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .frame(height: 62)
                }
                Spacer()
                if viewModel.sendError != nil {
                    Image(systemName: "x.circle")
                        .resizable()
                        .frame(width: 80, height: 80)
                } else {
                    Image(systemName: "checkmark")
                        .resizable()
                        .frame(width: 150, height: 150)
                }
                Spacer()
                if let error = viewModel.sendError {
                    Text(error.localizedDescription)
                        .font(Font.system(size: 20, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .navigationBarHidden(true)
    }
}

struct ConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmationView()
    }
}
