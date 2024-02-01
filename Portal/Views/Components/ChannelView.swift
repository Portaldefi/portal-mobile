//
// ChannelView.swift
// Portal
//
//  Created by farid on 23/8/22.
//

import SwiftUI
import PopupView
import PortalUI
import LightningDevKit

struct ChannelView: View {
    @StateObject private var viewModel = LNChannelViewModel()
    var peers: [Peer] = [Peer.alice, Peer.bob]
    
    func channelView(channel: ChannelDetails) -> some View {
        ZStack {
            Color.white.opacity(0.2).cornerRadius(12)
            
            VStack {
                HStack {
                    Text(peers.first{ $0.peerPubKey == channel.getCounterparty().getNodeId().toHexString() }!.name)
                    Spacer()
                    Text(channel.getCounterparty().getNodeId().toHexString().turnicated)
                        .font(.system(size: 14))
                }
                
                HStack {
                    Text("Channel id:")
                    Spacer()
                    Text(channel.getChannelId()!.toHexString().turnicated)
                        .font(.system(size: 14))
                }
                
                HStack {
                    Text("VALUE:")
                    Spacer()
                    Text("\(channel.getChannelValueSatoshis()) sats")
                }
                
                HStack {
                    Text("BALANCE:")
                    Spacer()
                    Text("\(channel.getBalanceMsat()/1000) sats")
                }
                
                if let inboundhtlcMin = channel.getInboundHtlcMinimumMsat() {
                    HStack {
                        Text("INBOUND HTLC MIN:")
                        Spacer()
                        Text("\(inboundhtlcMin/1000) sats")
                    }
                }
                
                if let inboundhtlcMax = channel.getInboundHtlcMaximumMsat() {
                    HStack {
                        Text("INBOUND HTLC MAX:")
                        Spacer()
                        Text("\(inboundhtlcMax/1000) sats")
                    }
                }
                
                HStack {
                    Text("INBOUND CAPACITY:")
                    Spacer()
                    Text("\(channel.getInboundCapacityMsat()/1000) sats")
                }
                
                HStack {
                    Text("OUTBOUND CAPACITY:")
                    Spacer()
                    Text("\(channel.getOutboundCapacityMsat()/1000) sats")
                }
                
                VStack(spacing: 12) {
                    Button {
                        viewModel.cooperativeClose()
                    } label: {
                        if viewModel.isOpeningChannel {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Text("Cooperative Close")
                                .font(.system(size: 16))
                        }
                    }
                    .disabled(viewModel.isOpeningChannel)
                    
                    Button {
                        viewModel.forceClose()
                    } label: {
                        if viewModel.isOpeningChannel {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            if let delay = channel.getForceCloseSpendDelay() {
                                Text("Force Close (\(delay) blocks delay)")
                                    .font(.system(size: 16))
                            } else {
                                Text("Force Close")
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    .disabled(viewModel.isOpeningChannel)
                }
                .padding(.vertical, 6)
            }
            .font(.system(size: 18))
            .padding()
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ScrollView {
                
                HStack {
                    Text("Peers")
                        .font(.system(size: 16))
                    Spacer()
                }
                .padding(.horizontal)
                
                HStack {
                    Spacer()

                    VStack(spacing: 15) {
                        Text("Alice")
                            .font(.system(size: 16))

                        Button {
                            if viewModel.peers.contains(Peer.alice.peerPubKey) {
                                viewModel.disconnect(peer: Peer.alice)
                            } else {
                                Task {
                                    await viewModel.connect(peer: Peer.alice)
                                }
                            }
                        } label: {
                            if viewModel.peers.contains(Peer.alice.peerPubKey) {
                                Text("Disconnect")
                                    .font(.system(size: 16))
                            } else {
                                Text("Connect")
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 15) {
                        Text("Bob")
                            .font(.system(size: 16))

                        Button {
                            if viewModel.peers.contains(Peer.bob.peerPubKey) {
                                viewModel.disconnect(peer: Peer.bob)
                            } else {
                                Task {
                                    await viewModel.connect(peer: Peer.bob)
                                }
                            }
                        } label: {
                            if viewModel.peers.contains(Peer.bob.peerPubKey) {
                                Text("Disconnect")
                                    .font(.system(size: 16))
                            } else {
                                Text("Connect")
                                    .font(.system(size: 16))
                            }
                        }
                    }
                    
                    Spacer()
                    
//                    VStack(spacing: 15) {
//                        Text("Carol")
//                            .font(.system(size: 16))
//
//                        Button {
//                            if viewModel.peers.contains(Peer.carol.peerPubKey) {
//                                viewModel.disconnect(peer: Peer.carol)
//                            } else {
//                                Task {
//                                    await viewModel.connect(peer: Peer.carol)
//                                }
//                            }
//                        } label: {
//                            if viewModel.peers.contains(Peer.carol.peerPubKey) {
//                                Text("Disconnect")
//                                    .font(.system(size: 16))
//                            } else {
//                                Text("Connect")
//                                    .font(.system(size: 16))
//                            }
//                        }
//                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                if !viewModel.peers.isEmpty {
                    HStack {
                        Text("Connected: ")
                            .font(.system(size: 16))
                        Spacer()
                    }
                    
                    ForEach(viewModel.peers, id: \.hashValue) { peerId in
                        ZStack {
                            Color.yellow.opacity(0.35).cornerRadius(12)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(peers.first{ $0.peerPubKey == peerId }!.name)
                                        .font(.system(size: 16))
                                    Spacer()
                                    Button {
                                        viewModel.isOpeningChannel.toggle()
                                        Task {
                                            await viewModel.openChannel(peer: peers.first{ $0.peerPubKey == peerId }!)
                                        }
                                    } label: {
                                        if viewModel.isOpeningChannel {
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                        } else {
                                            Text("Open new channel")
                                                .font(.system(size: 16))
                                        }
                                    }
                                    .disabled(viewModel.isOpeningChannel)
                                }
                                
                                Text(peerId)
                                    .font(.system(size: 16))
                            }
                            .padding()
                        }
                    }
                    
                    HStack {
                        Text("Channels: ")
                            .font(.system(size: 16))
                        Spacer()
                        Text("\(viewModel.usableChannels.count)")
                            .font(.system(size: 16))
                    }
                    .padding(.vertical)
                    
                    ForEach(viewModel.usableChannels, id: \.hashValue) { channel in
                        channelView(channel: channel)
                    }
                }
                
            }
        }
        .padding()
        .popup(isPresented: $viewModel.showMessage) {
            HStack {
                ZStack {
                    Circle()
                        .foregroundColor(Color(red: 0.191, green: 0.858, blue: 0.418))
                    Asset.warningIcon
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.black)
                }
                .frame(width: 32, height: 32)
                .padding(.horizontal, 12)
                
                Text(viewModel.message)
                    .padding(.vertical)
                    .font(.Main.fixed(.monoBold, size: 16))
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(width: 300)
            .frame(minHeight: 56)
            .background(Color(red: 0.165, green: 0.165, blue: 0.165))
            .cornerRadius(16)
        } customize: {
            $0.autohideIn(3).type(.floater()).position(.top).animation(.spring()).closeOnTapOutside(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
