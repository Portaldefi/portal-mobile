//
//  AwaitsFundingChannelView.swift
//  Portal
//
//  Created by farid on 20.12.2023.
//

import SwiftUI
import PortalUI

struct AwaitsFundingChannelView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var viewModel = AwaitsFundingViewModel()

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
                
                Text("Channel")
                    .frame(width: 300, height: 62)
                    .font(.Main.fixed(.monoBold, size: 16))
            }
            .padding(.horizontal, 18)
            
            VStack {
                Text(viewModel.confirmationsString + "/" + viewModel.totalConfirmationsRequiredString + " confirmations")
                    .font(.Main.fixed(.monoBold, size: 16))
                    .foregroundColor(.yellow)
                    .padding(.bottom, 8)
                
                Text("You’ll be able to use this channel when your creation transaction is confirmed in the blockchain.")
                    .multilineTextAlignment(.center)
                    .font(.Main.fixed(.monoMedium, size: 14))
                    .foregroundColor(Palette.grayScale8A)
            }
            .padding(16)
            .background(RoundedRectangle(cornerSize: .init(width: 20, height: 20)).foregroundColor(Palette.grayScale1A))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            
            HStack {
                Text("Node name")
                    .font(.Main.fixed(.monoMedium, size: 14))
                    .foregroundColor(Palette.grayScaleAA)
                Spacer()
                Text(viewModel.peer?.name ?? "Unknown name")
                    .font(.Main.fixed(.monoMedium, size: 16))
            }
            .padding(16)
            
            Divider()
                .frame(height: 1)
                .overlay(Palette.grayScale4A)
            
            HStack(alignment: .top) {
                Text("Public Key")
                    .font(.Main.fixed(.monoMedium, size: 14))
                    .foregroundColor(Palette.grayScaleAA)
                Spacer()
                Text(viewModel.peer?.peerPubKey ?? "Unknown pubKey")
                    .multilineTextAlignment(.leading)
                    .font(.Main.fixed(.monoMedium, size: 16))
            }
            .padding(16)
            
            Divider()
                .frame(height: 1)
                .overlay(Palette.grayScale4A)
            
            Spacer()
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
    }
}


#Preview {
    AwaitsFundingChannelView()
}
