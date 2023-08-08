//
//  TxSignConfirmationView.swift
//  Portal
//
//  Created by farid on 26.06.2023.
//

import SwiftUI
import PortalUI

struct TxSignConfirmationView: View {
    @StateObject private var viewModel = TxSignConfirmationViewModel()
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 25) {
                Text("Re-enter your 4-digit PIN")
                    .font(.Main.fixed(.monoBold, size: 26))
                    .foregroundColor(Palette.grayScaleCA)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .transition(.scale.combined(with: .opacity))
                
                if viewModel.state == .notMatched {
                    Text("Invalid pin. Try again.")
                        .frame(height: 88)
                        .font(.Main.fixed(.monoRegular, size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.red)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Spacer()
                        .frame(height: 88)
                }
                
                CircleProgressView(
                    totalPages: 4,
                    currentIndex: viewModel.pin.count
                )
                .frame(height: 25)
            }
            .padding(.horizontal, 20)
            
            NumpadView(onAdd: {
                viewModel.add(digit: $0)
            }, onRemove: {
                viewModel.removeLast()
            })
            .allowsHitTesting(viewModel.state == .notMatched ? false : true)
            .opacity(viewModel.state == .notMatched ? 0.8 : 1)
            .padding(.top, 65)
            
            Spacer()
        }
        .interactiveDismissDisabled(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .blur(radius: viewModel.requiredBiometrics ? 8 : 0)
        .onChange(of: viewModel.locked) { locked in
            guard !locked else { return }
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct TxSignConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        TxSignConfirmationView()
    }
}
