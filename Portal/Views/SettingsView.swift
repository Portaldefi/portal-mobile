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
//                Section(header: Text("Portfolio Currency")) {
//                    Picker(selection: $viewModel.fiatCurrencyIndex, label: EmptyView(), content: {
//                        Text("BTC").tag(1)
//                        Text("ETH").tag(2)
//                    })
//                    .pickerStyle(.inline)
//                }
                Section(header: Text("Fiat Currency")) {
                    Picker(selection: $viewModel.fiatCurrency, label: EmptyView(), content: {
                        ForEach(viewModel.fiatCurrencies, id: \.self) {
                            Text("\($0.symbol) \($0.name)").tag($0)
                        }
                    })
                    .pickerStyle(.inline)
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
