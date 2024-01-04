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

struct ChannelView: View {
    @ObservedObject private var viewModel = LightningStatstViewModel()
    @Environment(\.presentationMode) private var presentationMode
    @State private var peer: Peer?
    
    @Injected(Container.marketData) private var marketData
    
    init() {
        if let peerData = UserDefaults.standard.data(forKey: "NodeToConnect") {
            let decoder = JSONDecoder()
            if let peer = try? decoder.decode(Peer.self, from: peerData) {
                self._peer = State(initialValue: peer)
            }
        }
    }
    
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
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
    }
    
    func channelView(channel: ChannelDetails) -> some View {
        VStack {
            if let peer = peer {
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
                    guard let channelId = channel.getChannelId() else { return }
                    viewModel.cooperativeCloseChannel(id: channelId, counterPartyId: channel.getCounterparty().getNodeId())
                }
                
                if let delay = channel.getForceCloseSpendDelay() {
                    PButton(
                        config: .onlyLabel("Force Close (\(delay) blocks)"),
                        style: .outline,
                        size: .big,
                        enabled: true
                    ) {
                        guard let channelId = channel.getChannelId() else { return }
                        viewModel.forceCloseChannel(id: channelId, counterPartyId: channel.getCounterparty().getNodeId())
                    }
                } else {
                    PButton(
                        config: .onlyLabel("Force Close"),
                        style: .outline,
                        size: .big,
                        enabled: true
                    ) {
                        guard let channelId = channel.getChannelId() else { return }
                        viewModel.forceCloseChannel(id: channelId, counterPartyId: channel.getCounterparty().getNodeId())
                    }
                }
                
                
            }
            .padding(16)
        }
    }
}

#Preview {
    ChannelView()
}
