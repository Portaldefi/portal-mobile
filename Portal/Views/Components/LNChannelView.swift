//
//  ChannelView.swift
//  Portal
//
//  Created by farid on 04.01.2024.
//

import SwiftUI
import LightningDevKit
import Factory
import PortalUI

struct LNChannelView: View {
    @ObservedObject private var viewModel = LNChannelViewModel()
    @Environment(\.presentationMode) private var presentationMode
    
    @Injected(Container.marketData) private var marketData
        
    var body: some View {
        VStack {
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
            .padding(.horizontal, 16)
            
            ScrollView {
                ForEach(viewModel.usableChannels, id: \.hashValue) { channel in
                    channelView(channel: channel)
                }
            }
            
            Spacer()
        }
        .alert(isPresented: $viewModel.showChannelCloseAlert) {
            switch viewModel.alertType {
            case .cooperativeClose:
                Alert(
                    title: Text("Cooperative Channel Close"),
                    primaryButton: .cancel(),
                    secondaryButton: .destructive(Text("Close"), action: {
                        viewModel.cooperativeClose()
                        presentationMode.wrappedValue.dismiss()
                    })
                )
            case .forceClose:
                Alert(
                    title: Text("Force Channel Close"),
                    primaryButton: .cancel(),
                    secondaryButton: .destructive(Text("Close"), action: {
                        viewModel.forceClose()
                        presentationMode.wrappedValue.dismiss()
                    })
                )
            }
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
    }
    
    func channelView(channel: ChannelDetails) -> some View {
        VStack {
            if let peer = viewModel.peer {
                HStack {
                    Text("Node Name")
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(Palette.grayScaleAA)
                    Spacer()
                    Text(peer.name)
                        .font(.Main.fixed(.monoBold, size: 16))
                        .foregroundColor(Palette.grayScaleF4)
                }
                .padding(.horizontal, 16)
                
                Divider()
                    .frame(height: 1)
                    .overlay(Palette.grayScale4A)
                
                HStack(alignment: .top) {
                    Text("Public key")
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(Palette.grayScaleAA)
                    Spacer()
                    Text(peer.peerPubKey)
                        .multilineTextAlignment(.leading)
                        .font(.Main.fixed(.monoBold, size: 16))
                        .foregroundColor(Palette.grayScaleF4)
                }
                .padding(.horizontal, 16)

                Divider()
                    .frame(height: 1)
                    .overlay(Palette.grayScale4A)
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text("Total value locked")
                    .font(.Main.fixed(.monoBold, size: 14))
                    .foregroundColor(Palette.grayScaleAA)
                    .offset(y: -10)
                Spacer()
                
                VStack(alignment: .trailing) {
                    HStack(alignment: .lastTextBaseline) {
                        Text(String(describing: Decimal(channel.getChannelValueSatoshis())/100_000_000))
                            .font(.Main.fixed(.monoBold, size: 32))
                            .foregroundColor(Palette.grayScaleEA)
                        Text("btc")
                            .font(.Main.fixed(.monoBold, size: 14))
                            .foregroundColor(Palette.grayScale6A)
                    }
                    
                    Text("\(((Decimal(channel.getChannelValueSatoshis())/100_000_000).double * marketData.lastSeenBtcPrice.double).usdFormatted()) USD")
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(Palette.grayScale6A)
                }
            }
            .padding(.horizontal, 16)

            Divider()
                .frame(height: 1)
                .overlay(Palette.grayScale4A)
                        
            HStack(alignment: .firstTextBaseline) {
                Text("Balance")
                    .font(.Main.fixed(.monoBold, size: 14))
                    .foregroundColor(Palette.grayScaleAA)
                Spacer()
                
                VStack(alignment: .trailing) {
                    HStack(alignment: .lastTextBaseline) {
                        Text(String(describing: Decimal(channel.getBalanceMsat())/100/100_000_000))
                            .font(.Main.fixed(.monoBold, size: 18))
                            .foregroundColor(Palette.grayScaleEA)
                        Text("BTC")
                            .font(.Main.fixed(.monoBold, size: 14))
                            .foregroundColor(Palette.grayScaleEA)
                    }
                    
                    Text("\(((Decimal(channel.getBalanceMsat())/100/100_000_000).double * marketData.lastSeenBtcPrice.double).usdFormatted()) USD")
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(Palette.grayScale6A)
                }
            }
            .padding(.horizontal, 16)

            Divider()
                .frame(height: 1)
                .overlay(Palette.grayScale4A)
                        
            HStack(alignment: .firstTextBaseline) {
                Text("Inbound Capacity")
                    .font(.Main.fixed(.monoBold, size: 14))
                    .foregroundColor(Palette.grayScaleAA)
                Spacer()
                
                VStack(alignment: .trailing) {
                    HStack(alignment: .lastTextBaseline) {
                        Text(String(describing: Decimal(channel.getInboundCapacityMsat())/100/100_000_000))
                            .font(.Main.fixed(.monoBold, size: 18))
                            .foregroundColor(Palette.grayScaleEA)
                        Text("BTC")
                            .font(.Main.fixed(.monoBold, size: 14))
                            .foregroundColor(Palette.grayScaleEA)
                    }
                    
                    Text("\(((Decimal(channel.getInboundCapacityMsat())/100/100_000_000).double * marketData.lastSeenBtcPrice.double).usdFormatted()) USD")
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(Palette.grayScale6A)
                }
            }
            .padding(.horizontal, 16)

            Divider()
                .frame(height: 1)
                .overlay(Palette.grayScale4A)
            
            HStack(alignment: .firstTextBaseline) {
                Text("Outbound Capacity")
                    .font(.Main.fixed(.monoBold, size: 14))
                    .foregroundColor(Palette.grayScaleAA)
                Spacer()
                
                VStack(alignment: .trailing) {
                    HStack(alignment: .lastTextBaseline) {
                        Text(String(describing: Decimal(channel.getOutboundCapacityMsat())/100/100_000_000))
                            .font(.Main.fixed(.monoBold, size: 18))
                            .foregroundColor(Palette.grayScaleEA)
                        Text("BTC")
                            .font(.Main.fixed(.monoBold, size: 14))
                            .foregroundColor(Palette.grayScaleEA)
                    }
                    
                    Text("\(((Decimal(channel.getOutboundCapacityMsat())/100/100_000_000).double * marketData.lastSeenBtcPrice.double).usdFormatted()) USD")
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(Palette.grayScale6A)
                }
            }
            .padding(.horizontal, 16)

            Divider()
                .frame(height: 1)
                .overlay(Palette.grayScale4A)
            
            VStack(spacing: 16) {
                PButton(
                    config: .onlyLabel("Cooperative close"),
                    style: .outline,
                    size: .big,
                    enabled: true
                ) {
                    viewModel.showChannelChannelClose(type: .cooperativeClose)
                }
                
                if let delay = channel.getForceCloseSpendDelay() {
                    PButton(
                        config: .onlyLabel("Force Close (\(delay) blocks)"),
                        style: .outline,
                        size: .big,
                        enabled: true
                    ) {
                        viewModel.showChannelChannelClose(type: .forceClose)
                    }
                } else {
                    PButton(
                        config: .onlyLabel("Force Close"),
                        style: .outline,
                        size: .big,
                        enabled: true
                    ) {
                        viewModel.showChannelChannelClose(type: .forceClose)
                    }
                }
                
                
            }
            .padding(16)
        }
    }
}

#Preview {
    LNChannelView()
}
