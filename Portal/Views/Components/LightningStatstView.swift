//
//  LightningStatstView.swift
// Portal
//
//  Created by farid on 23/8/22.
//

import SwiftUI
import Factory
import PopupView
import PortalUI
import Lightning
import LightningDevKit

class LightningStatstViewModel: ObservableObject {
    private let ldkManager = Container.lightningKitManager()
    
    @Published var peers: [String] = []
    @Published var showError: Bool = false
    @Published var errorMessage: String = String()
    @Published var isOpeningChannel: Bool = false
    
    var allChannels: [ChannelDetails] {
        ldkManager.allChannels
    }
    
    var usableChannels: [ChannelDetails] {
        ldkManager.usableChannels
    }
    
    init() {
        ldkManager.activePeersPublisher.assign(to: &$peers)
    }
    
    func openChannel(peer: Peer) async {
        do {
            try await ldkManager.openChannel(peer: peer)
            DispatchQueue.main.async {
                self.errorMessage = "Channel is opened! Wait for fundind tx is confirmed on-chain"
                self.isOpeningChannel.toggle()
                self.showError.toggle()
            }
        } catch {
            DispatchQueue.main.async {
                if let apiError = error as? NodeError.Channels {
                    self.errorMessage = apiError.description
                } else {
                    self.errorMessage = error.localizedDescription
                }
                self.showError.toggle()
                self.isOpeningChannel.toggle()
            }
        }
    }
    
    func connect(peer: Peer) async {
        do {
            try await ldkManager.connectPeer(peer)
            DispatchQueue.main.async {
                self.errorMessage = "Connected to \(peer.name)"
                self.showError.toggle()
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed connect to \(peer.name)"
                self.showError.toggle()
            }
        }
    }
    
    func disconnect(peer: Peer) {
        do {
            try ldkManager.disconnectPeer(peer)
            DispatchQueue.main.async {
                self.errorMessage = "Disconnected from \(peer.name)"
                self.showError.toggle()
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed connect disconnect \(peer.name)"
                self.showError.toggle()
            }
        }
    }
}

struct LightningStatstView: View {
    @StateObject private var viewModel = LightningStatstViewModel()
    var peers: [Peer] = [Peer.alice, Peer.bob, Peer.carol]
    
    func channelView(channel: ChannelDetails) -> some View {
        ZStack {
            Color.white.opacity(0.2).cornerRadius(12)
            
            VStack {
                HStack {
                    Text(peers.first{ $0.peerPubKey == channel.get_counterparty().get_node_id().toHexString() }!.name)
                    Spacer()
                    Text(channel.get_counterparty().get_node_id().toHexString().turnicated)
                        .font(.system(size: 14))
                }
                
                HStack {
                    Text("Channel id:")
                    Spacer()
                    Text(channel.get_channel_id().toHexString().turnicated)
                        .font(.system(size: 14))
                }
                
                HStack {
                    Text("VALUE:")
                    Spacer()
                    Text("\(channel.get_channel_value_satoshis()) sats")
                }
                
                HStack {
                    Text("BALANCE:")
                    Spacer()
                    Text("\(channel.get_balance_msat()/1000) sats")
                }
                
                if let inboundhtlcMin = channel.get_inbound_htlc_minimum_msat().getValue() {
                    HStack {
                        Text("INBOUND HTLC MIN:")
                        Spacer()
                        Text("\(inboundhtlcMin/1000) sats")
                    }
                }
                
                if let inboundhtlcMax = channel.get_inbound_htlc_maximum_msat().getValue() {
                    HStack {
                        Text("INBOUND HTLC MAX:")
                        Spacer()
                        Text("\(inboundhtlcMax/1000) sats")
                    }
                }
                
                HStack {
                    Text("INBOUND CAPACITY:")
                    Spacer()
                    Text("\(channel.get_inbound_capacity_msat()/1000) sats")
                }
                
                HStack {
                    Text("OUTBOUND CAPACITY:")
                    Spacer()
                    Text("\(channel.get_outbound_capacity_msat()/1000) sats")
                }
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
                
                HStack {
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
                    
                    VStack(spacing: 15) {
                        Text("Carol")
                            .font(.system(size: 16))

                        Button {
                            if viewModel.peers.contains(Peer.carol.peerPubKey) {
                                viewModel.disconnect(peer: Peer.carol)
                            } else {
                                Task {
                                    await viewModel.connect(peer: Peer.carol)
                                }
                            }
                        } label: {
                            if viewModel.peers.contains(Peer.carol.peerPubKey) {
                                Text("Disconnect")
                                    .font(.system(size: 16))
                            } else {
                                Text("Connect")
                                    .font(.system(size: 16))
                            }
                        }
                    }
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
        .popup(isPresented: $viewModel.showError) {
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
                
                Text(viewModel.errorMessage)
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
