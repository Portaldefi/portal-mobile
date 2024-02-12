//
//  SelectPeerView.swift
//  Portal
//
//  Created by farid on 20.12.2023.
//

import SwiftUI
import Factory
import PortalUI

struct SelectPeerView: View {
    private var viewState: ViewState = Container.viewState()
    @State private var viewModel = OpenChannelViewModel.config()
    @State private var isConnecting = false
    @Environment(\.presentationMode) private var presentationMode
    @Environment(NavigationStack.self) private var navigation: NavigationStack
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    PButton(config: .onlyIcon(Asset.xIcon), style: .free, size: .medium, enabled: true) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(width: 20)
                    
                    Spacer()
                }
                
                Text("Select a Peer")
                    .frame(width: 300, height: 62)
                    .font(.Main.fixed(.monoBold, size: 16))
            }
            .padding(.horizontal, 10)
                        
            if !viewState.isReachable {
                NoInternetConnectionView()
                    .padding(.horizontal, -16)
            }
            
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(viewModel.peers) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.Main.fixed(.monoMedium, size: 14))
                                Text(item.peerPubKey)
                                    .font(.Main.fixed(.monoMedium, size: 12))
                                    .foregroundColor(Palette.grayScale8A)
                            }
                            
                            Spacer()
                            
                            if isConnecting {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            } else {
                                Asset.chevronRightIcon
                                    .foregroundColor(Palette.grayScale4A)
                            }
                        }
                        .frame(height: 87)
//                        .padding(.horizontal, 16)
                        .contentShape(.rect)
                        .onTapGesture {
                            isConnecting.toggle()
                            
                            viewModel.connect(item) { success in
                                if success {
                                    navigation.push(.createChannelView(peer: item))
                                } else {
                                    print("Unable to connect to \(item.name)")
                                }
                                isConnecting.toggle()
                            }
                        }
                        
                        Divider()
                            .frame(height: 1)
                            .overlay(Color(red: 42/255, green: 42/255, blue: 42/255))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 32)
                
                VStack {
                    Text("Non-Custodial Lightning Beta")
                        .font(.Main.fixed(.monoBold, size: 16))
                        .foregroundColor(Palette.grayScaleCA)
                        .padding(.bottom, 8)
                    
                    Text("For this beta version, connect to this well known public peers.")
                        .multilineTextAlignment(.center)
                        .font(.Main.fixed(.monoMedium, size: 14))
                        .foregroundColor(Palette.grayScale8A)
                    
                    Text("We’ll allow custom nodes later.")
                        .multilineTextAlignment(.center)
                        .font(.Main.fixed(.monoMedium, size: 14))
                        .foregroundColor(Palette.grayScale8A)
                        .padding()
                }
                .padding(16)
                .background(RoundedRectangle(cornerSize: .init(width: 20, height: 20)).foregroundColor(Palette.grayScale1A))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
            }
            .padding(.top, 16)
            .padding(.horizontal, 8)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .disabled(isConnecting)
        .if(isConnecting, then: { view in
            view.opacity(0.65)
        }, else: { view in
            view.opacity(1)
        })

    }
}

#Preview {
    SelectPeerView()
}
