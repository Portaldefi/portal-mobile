//
//  SettingsView.swift
//  Portal
//
//  Created by farid on 23.05.2023.
//

import SwiftUI
import PortalUI
import Factory

struct MultipleSelectionRow: View {
    let title: String
    let imageUrl: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                CoinImageView(size: 24, url: imageUrl)
                Text(title)
                    .foregroundColor(.white)
                if isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject var viewModel = SettingsViewViewModel()
    
    var body: some View {
        VStack {
            HStack {
                Text("Settings")
                    .multilineTextAlignment(.center)
                    .font(.Main.fixed(.monoBold, size: 26))
                    .foregroundColor(Palette.grayScaleCA)
                
                Spacer()
                
                PButton(config: .onlyIcon(Asset.xIcon), style: .free, size: .medium, enabled: true) {
                    presentationMode.wrappedValue.dismiss()
                }
                .frame(width: 20)
            }
            .animation(nil, value: false)
            .padding(.horizontal, 16)
            
            List {                
                Section(header: Text("Portfolio Currency")) {
                    Picker(selection: $viewModel.portfolioCurrencyIndex, label: EmptyView(), content: {
                        ForEach(0...viewModel.portfolioCurrencies.count - 1, id: \.self) { i in
                            Text(viewModel.portfolioCurrencies[i].name).tag(i)
                        }
                    })
                    .pickerStyle(.inline)
                }
                
                Section(header: Text("Base asset")) {
                    Picker(selection: $viewModel.fiatCurrency, label: EmptyView(), content: {
                        ForEach(viewModel.fiatCurrencies, id: \.name) {
                            Text("\($0.symbol) \($0.name)").tag($0)
                        }
                    })
                    .pickerStyle(.inline)
                }
                
                Section(header: Text("Wallet Coins")) {
                    ForEach(viewModel.coins, id: \.self) { coin in
                        MultipleSelectionRow(
                            title: coin.name,
                            imageUrl: coin.icon,
                            isSelected: viewModel.selectedCoins.contains(coin)
                        ) {
                            DispatchQueue.main.async {
                                if viewModel.selectedCoins.contains(coin) {
                                    viewModel.selectedCoins.removeAll(where: { $0 == coin })
                                } else {
                                    viewModel.selectedCoins.append(coin)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 6)
            
            Spacer()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
