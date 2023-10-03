//
//  SecuritySettingsView.swift
//  Portal
//
//  Created by farid on 07.06.2023.
//

import SwiftUI
import PortalUI

struct SecuritySettingsView: View {
    @Environment(NavigationStack.self) var navigation: NavigationStack
    @StateObject var viewModel = SecuritySettingsViewModel()
    let canGoBack: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                    navigation.pop()
                }
                .frame(width: 20)
                .opacity(canGoBack ? 1 : 0)
                
                Spacer()
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 22)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Improve your security")
                    .font(.Main.fixed(.monoBold, size: 26))
                    .foregroundColor(Palette.grayScaleCA)
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Enable PIN or Face ID to ensure\nonly you can access the wallet and transact with your funds.")
                    .font(.Main.fixed(.monoRegular, size: 16))
                    .foregroundColor(Palette.grayScale8A)
                
                Divider()
                    .frame(height: 1)
                    .background(Palette.grayScale2A)

            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PIN")
                            .font(.Main.fixed(.monoBold, size: 20))
                            .foregroundColor(Palette.grayScaleF4)
                        Text("Set a 4-digit code to protect from unwanted access.")
                            .font(.Main.fixed(.monoRegular, size: 16))
                            .foregroundColor(Palette.grayScale8A)
                    }
                    .layoutPriority(1)
                    
                    ZStack {
                        Toggle(isOn: $viewModel.pinCodeEnabled) {
                            EmptyView()
                        }
                        .allowsHitTesting(viewModel.pinCodeEnabled ? true : false)
                        
                        if !viewModel.pinCodeEnabled {
                            Rectangle().opacity(0.00001)
                                .frame(maxHeight: 40)
                                .onTapGesture {
                                    navigation.push(.setPinCode)
                                }
                        }
                    }
                }
                .containerShape(Rectangle())
                .onTapGesture {
                    if !viewModel.pinCodeEnabled {
                        navigation.push(.setPinCode)
                    }
                }
                
                Divider()
                    .frame(height: 1)
                    .background(Palette.grayScale2A)

            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Face ID")
                            .font(.Main.fixed(.monoBold, size: 20))
                            .foregroundColor(Palette.grayScaleF4)
                        Text("Require detection of your face for wallet access.")
                            .font(.Main.fixed(.monoRegular, size: 16))
                            .foregroundColor(Palette.grayScale8A)
                    }
                    .layoutPriority(1)
                                        
                    Toggle(isOn: $viewModel.biometricEnabled) {
                        EmptyView()
                    }
                }
                
                Divider()
                    .frame(height: 1)
                    .background(Palette.grayScale2A)

            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
        
            
            Spacer()
        }
    }
}

struct SecuritySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SecuritySettingsView(canGoBack: true)
    }
}
