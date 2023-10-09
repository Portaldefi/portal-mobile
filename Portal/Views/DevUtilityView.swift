//
//  DevUtilityView.swift
//  Portal
//
//  Created by farid on 19.09.2023.
//

import SwiftUI
import PortalUI
import PopupView

import Combine
import Lightning
import Factory

struct DevUtilityView: View {
    @Environment(NavigationStack.self) var navigation: NavigationStack
    @State private var utilityService: DevUtilityService
    
    init() {
        _utilityService = State(initialValue: DevUtilityService())
    }
    
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
            .padding(.bottom, 22)
        
            List {
                Section(header: Text("Bitcoin")) {
                    Text("Send 1 btc to own account")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await utilityService.btcSend1ToOwnAccount() }
                        }
                    
                    Text("Generate new address")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task {
                                UIPasteboard.general.string = try await utilityService.getNewAddress()
                            }
                        }
                    
                    Text("Mine 1 block")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await utilityService.btcMineBlocks() }
                        }
                    
                    Text("Mine 6 block")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await utilityService.btcMineBlocks(count: 6) }
                        }
                }
                .headerProminence(.increased)
                
                Section(header: Text("Lightning: Alice")) {
                    Text("Fetch pubKey")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await utilityService.fetchAlicePubKey() }
                        }
                    Text("Add Invoice")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await utilityService.aliceCreateInvoice(amount: 10000) }
                        }
                    Text("Pay Invoice")
                }
                .headerProminence(.increased)
                
                Section(header: Text("Lightning: Bob")) {
                    Text("Fetch pubKey")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await utilityService.fetchBobPubKey() }
                        }
                    Text("Add Invoice")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await utilityService.bobCreateInvoice(amount: 10000) }
                        }
                    Text("Pay Invoice")
                }
                .headerProminence(.increased)
                
                Section(header: Text("Ethereum")) {
                    Text("Send 1 eth to own address")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            Task { await utilityService.send1EthToOwnAddress() }
                        }
                }
                .headerProminence(.increased)
            }
            .padding(.horizontal, 6)
            
            Spacer()
        }
        //Confirmation alert
        .popup(isPresented: $utilityService.showConfirmationAlert) {
            if let confirmationAlertType = utilityService.confirmationAlertType {
                HStack {
                    ZStack {
                        Circle()
                            .foregroundColor(Color(red: 0.191, green: 0.858, blue: 0.418))
                        Asset.checkIcon
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.black)
                    }
                    .frame(width: 32, height: 32)
                    .padding(.horizontal, 12)
                    
                    switch confirmationAlertType {
                    case .sent1BtcToOwnAddress(let txID):
                        Text("Tx id: \(txID)")
                            .multilineTextAlignment(.leading)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                    case .mined1Block(let txID):
                        Text("Tx id: \(txID)")
                            .multilineTextAlignment(.leading)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                    case .generatedAddress(let address):
                        Text("\(address)/n copied to clipboard")
                            .multilineTextAlignment(.leading)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                    case .sent1EthToOwnAccount(let txID):
                        Text("Tx id: \(txID)")
                            .multilineTextAlignment(.leading)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                    case .aliceCreatesInvoice(let invoice):
                        Text(invoice)
                            .multilineTextAlignment(.leading)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                    case .bobCreatesInvoice(let invoice):
                        Text(invoice)
                            .multilineTextAlignment(.leading)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                    }
                    Spacer()
                }
                .frame(width: 300)
                .background(Color(red: 0.165, green: 0.165, blue: 0.165))
                .cornerRadius(16)
            } else {
                EmptyView()
            }
        } customize: {
            $0.autohideIn(2).type(.floater()).position(.top).animation(.spring()).closeOnTapOutside(true)
        }
        //Error alert
        .popup(isPresented: $utilityService.showErrorAlert) {
            if let errorAlertType = utilityService.errorAlertType {
                HStack {
                    ZStack {
                        Circle()
                            .foregroundColor(Color.red)
                        Asset.checkIcon
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.black)
                    }
                    .frame(width: 32, height: 32)
                    .padding(.horizontal, 12)
                    
                    switch errorAlertType {
                    case .sending1BtcToOwnAddress(let error):
                        Text(error)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                    case .miningBlock(let error):
                        Text(error)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                    case .sending1EthToOwnAccount(let error):
                        Text(error)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                    case .aliceCreatingInvoice(let error):
                        Text(error)
                            .font(.Main.fixed(.monoBold, size: 16))
                    case .bobCreatingInvoice(let error):
                        Text(error)
                            .font(.Main.fixed(.monoBold, size: 16))
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
                .frame(width: 300)
                .background(Color(red: 0.165, green: 0.165, blue: 0.165))
                .cornerRadius(16)
            } else {
                EmptyView()
            }
        } customize: {
            $0.autohideIn(5).type(.floater()).position(.top).animation(.spring()).closeOnTapOutside(true)
        }
    }
}

struct DevUtilityView_Previews: PreviewProvider {
    static var previews: some View {
        DevUtilityView()
    }
}
