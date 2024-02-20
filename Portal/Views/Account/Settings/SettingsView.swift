//
//  SettingsView.swift
//  Portal
//
//  Created by farid on 23.05.2023.
//

import SwiftUI
import PortalUI
import Factory

struct SettingsView: View {
    @State private var notificationsEnabled = false
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel = SettingsViewViewModel()
    @Environment(NavigationStack.self) var navigation: NavigationStack
    @Injected(Container.configProvider) var config

    var body: some View {
        VStack {
            HStack {
                Text("Settings")
                    .multilineTextAlignment(.center)
                    .font(.Main.fixed(.monoBold, size: 26))
                    .foregroundColor(Palette.grayScaleCA)
                
                Spacer()
                
                PButton(config: .onlyIcon(Asset.xIcon), style: .free, size: .medium, enabled: true) {
                    viewModel.updateWallet()
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(width: 20)
            }
            .animation(nil, value: false)
            .padding(.horizontal, 16)
            
            List {
                if config.network == .playnet {
                    Section(header: EmptyView()) {
                        HStack{
                            Text("Dev Utility")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Image(systemName: "chevron.forward")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        navigation.push(.devUtility)
                    }
                }
                
                Section(header: Text("Notifications")) {
                    HStack{
                        Text("Incoming transactions")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Toggle(isOn: $viewModel.notificationsEnabled) {
                            EmptyView()
                        }
                        .disabled(!notificationsEnabled)
                    }
                }
                
                Section(header: EmptyView()) {
                    HStack{
                        Text("Security")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "chevron.forward")
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    navigation.push(.securitySettings)
                }
                
                Section(header: Text("Portfolio Currency")) {
                    Picker(selection: $viewModel.portfolioCurrencyIndex, label: EmptyView(), content: {
                        ForEach(0...viewModel.portfolioCurrencies.count - 1, id: \.self) { i in
                            Text(viewModel.portfolioCurrencies[i].name).tag(i)
                        }
                    })
                    .pickerStyle(.inline)
                }
                
                if !viewModel.fiatCurrencies.isEmpty {
                    Section(header: Text("Base asset")) {
                        Picker(selection: $viewModel.fiatCurrency, label: EmptyView(), content: {
                            ForEach(viewModel.fiatCurrencies, id: \.code) {
                                Text("\($0.symbol) \($0.name)").tag($0)
                            }
                        })
                        .pickerStyle(.inline)
                    }
                }
                
//                Section(header: Text("Wallet Coins")) {
//                    ForEach(viewModel.coins, id: \.self) { coin in
//                        MultipleSelectionRow(
//                            title: coin.name,
//                            imageUrl: coin.icon,
//                            isSelected: viewModel.selectedCoins.contains(coin)
//                        ) {
//                            DispatchQueue.main.async {
//                                viewModel.updatedWallet(coin)
//                            }
//                        }
//                    }
//                }
            }
            .padding(.horizontal, 6)
            
            Spacer()
        }
        .onAppear {
            Task {
                notificationsEnabled = await viewModel.isNotificationsEnrolled()
                guard !notificationsEnabled && viewModel.notificationsEnabled else { return }
                viewModel.notificationsEnabled = false
            }
        }
        .onReceive(viewModel.notificationsEnrolledPublisher.receive(on: RunLoop.main)) { enabled in
            guard notificationsEnabled != enabled else { return }
            notificationsEnabled = enabled
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
