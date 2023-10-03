//
//  SetPincodeView.swift
//  Portal
//
//  Created by farid on 08.06.2023.
//

import SwiftUI
import PortalUI

struct PinButtonStyle: ButtonStyle {
  func makeBody(configuration: Self.Configuration) -> some View {
      configuration.label
          .frame(height: 45)
          .frame(maxWidth: .infinity)
          .clipShape(Rectangle())
          .foregroundColor(configuration.isPressed ? .black : .white)
          .background(configuration.isPressed ? Color.white.opacity(0.9) : Color.clear)
  }
}

struct SetPincodeView: View {
    @StateObject private var viewModel = SetPincodeViewModel()
    @Environment(NavigationStack.self) var navigation: NavigationStack

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                    navigation.pop()
                }
                .frame(width: 20)
                
                Spacer()
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 65)
            
            VStack(spacing: 25) {
                switch viewModel.state {
                case .choose:
                    Text("Choose a 4-digit PIN")
                        .font(.Main.fixed(.monoBold, size: 26))
                        .foregroundColor(Palette.grayScaleCA)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.scale.combined(with: .opacity))
                    
                    Text("PIN entry will be required for wallet access and transactions. Write it down as it cannot be recovered.")
                        .frame(height: 88)
                        .font(.Main.fixed(.monoRegular, size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Palette.grayScale8A)
                        .transition(.scale.combined(with: .opacity))

                case .confirm, .notMatched:
                    Text("Confirm your PIN")
                        .font(.Main.fixed(.monoBold, size: 26))
                        .foregroundColor(Palette.grayScaleCA)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .transition(.scale.combined(with: .opacity))
                    
                    if viewModel.state == .notMatched {
                        Text("Pin did not match, try again.")
                            .frame(height: 88)
                            .font(.Main.fixed(.monoRegular, size: 16))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.red)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Text("Re-enter your 4-digit PIN")
                            .frame(height: 88)
                            .font(.Main.fixed(.monoRegular, size: 16))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Palette.grayScale8A)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                CircleProgressView(
                    totalPages: 4,
                    currentIndex: viewModel.state == .choose ? viewModel.pin.count : viewModel.pinConfirmation.count
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
        .onReceive(viewModel.$pinIsSet.filter{$0}) { _ in
            navigation.pop()
        }
    }
}

struct SetPincodeView_Previews: PreviewProvider {
    static var previews: some View {
        SetPincodeView()
    }
}
