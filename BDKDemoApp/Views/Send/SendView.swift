//
//  SendView.swift
//  BDKDemoApp
//
//  Created by farid on 26/8/22.
//

import SwiftUI
import PortalUI
import Factory

struct SendView: View {
    @FocusState private var isFocused: Bool
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var viewModel: SendViewViewModel = Container.sendViewModel()
    @Injected(Container.viewState) private var viewState
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                        withAnimation {
                            if viewModel.goBack() {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                    }
                    .frame(width: 20)
                    
                    Spacer()
                }
                
                Text(viewModel.title)
                    .frame(width: 300, height: 62)
                    .font(.Main.fixed(.bold, size: 16))
                    .animation(nil)
            }
            
            switch viewModel.step {
            case .recipient:
                SetRecipientView(viewModel: viewModel)
                    .transition(.slide.combined(with: .scale))
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .amount:
                SetAmountView()
                    .transition(.slide.combined(with: .scale))
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .review:
                Text("Review")
                    .transition(.slide.combined(with: .scale))
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .confirmation:
                Text("Confirmation")
                    .transition(.slide.combined(with: .scale))
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
            
            Spacer()
            
            switch viewModel.step {
            case .recipient, .amount, .review:
                PButton(config: .onlyLabel(viewModel.actionButtonTitle), style: .filled, size: .big, enabled: viewModel.actionButtonEnabled) {
                    withAnimation {
                        viewModel.onActionButtonPressed()
                    }
                }
            case .confirmation:
                PButton(config: .onlyLabel("Done"), style: .outline, size: .big, enabled: true) {
                    
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.qrScannerOpened, onDismiss: {
            viewModel.qrScannerOpened = false
        }) {
            QRCodeReaderView(config: .send) { item in
                viewModel.qrCodeItem = item
                
                switch item.type {
                case .bip21(let address, let amount, _):
                    viewModel.to = address
                    guard let _amount = amount else { return }
                    viewModel.amount = _amount
                default:
                    break
                }
            }
        }
    }
}

struct SendView_Previews: PreviewProvider {
    static var previews: some View {
        SendView()
    }
}
