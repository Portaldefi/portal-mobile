//
//  SendView.swift
//  BDKDemoApp
//
//  Created by farid on 7/25/22.
//

import SwiftUI
import Combine

struct SendView: View {
    @State var to: String = ""
    @State var amount: String = "0"
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var viewModel: WalletViewModel
    
    init(viewModel: WalletViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Recipient").textStyle(BasicTextStyle(white: true))) {
                    TextField("Address", text: $to)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                }
                Section(header: Text("Amount (sats)").textStyle(BasicTextStyle(white: true))) {
                    TextField("Amount", text: $amount)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.numberPad)
                        .onReceive(Just(amount)) { newValue in
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue {
                                self.amount = filtered
                            }
                        }
                }
            }
            .onAppear {
                UITableView.appearance().backgroundColor = .clear
            }
            
            Spacer()
            
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Send")
                    .foregroundColor(.black)
                    .font(.system(size: 16, design: .monospaced))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.blue)
                    .background(in: RoundedRectangle(cornerRadius: 10))
                    .frame(height: 40)
            }
            .disabled(to == "" || (Double(amount) ?? 0) == 0)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .padding()
        }
            .navigationTitle("Send Bitcoin")
            .modifier(BackButtonModifier())
    }
}

struct SendView_Previews: PreviewProvider {
    static var previews: some View {
        SendView(viewModel: WalletViewModel.mocked())
    }
}
