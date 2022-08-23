//
//  SendView.swift
//  BDKDemoApp
//
//  Created by farid on 7/25/22.
//

import SwiftUI
import Combine
import BitcoinAddressValidator

struct SendView: View {
    private let item: QRCodeItem?
    @State private var to: String
    @State private var amount: String
    private var signalAlert = PassthroughSubject<Error, Never>()
    private var window = UIApplication.shared.connectedScenes
    // Keep only active scenes, onscreen and visible to the user
        .filter { $0.activationState == .foregroundActive }
    // Keep only the first `UIWindowScene`
        .first(where: { $0 is UIWindowScene })
    // Get its associated windows
        .flatMap({ $0 as? UIWindowScene })?.windows
    // Finally, keep only the key window
        .first(where: \.isKeyWindow)
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var viewModel: AccountViewModel
    
    init(item: QRCodeItem?) {
        UITableView.appearance().backgroundColor = .clear
        
        self.item = item
        
        switch item?.type {
        case .bip21(let address, let amount, _):
            _to = State(initialValue: address)
            guard let amount = amount else {
                _amount = State(initialValue: "0")
                return
            }
            _amount = State(initialValue: amount)
        default:
            _to = State(initialValue: String())
            _amount = State(initialValue: "0")
        }
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
            
            Spacer()
            
            Button {
                viewModel.send(to: to, amount: amount, completion: { error in
                    guard let error = error else {
                        showConfirmationAlert()
                        return
                    }
                    signalAlert.send(error)
                })
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
            .disabled(!BitcoinAddressValidator.isValid(address: to) || (Double(amount) ?? 0) == 0)
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .padding()
        }
        .navigationTitle("Send Bitcoin")
        .modifier(BackButtonModifier())
        .onReceive(signalAlert) { error in
            showAlert(error: error)
        }
    }
    
    private func showAlert(error: Error) {
        let alert =  UIAlertController(title: "Send error", message: "\(error)", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Dismiss", style: .default) { (action) in
            print("Alert dismissed")
        }
        alert.addAction(dismissAction)
        
        DispatchQueue.main.async {
            window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    
    private func showConfirmationAlert() {
        let alert =  UIAlertController(title: "\(amount) sat sent!", message: "to: \(to)", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Ok", style: .default) { (action) in
            presentationMode.wrappedValue.dismiss()
        }
        alert.addAction(dismissAction)
        
        DispatchQueue.main.async {
            window?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
}

struct SendView_Previews: PreviewProvider {
    static var previews: some View {
        SendView(item: nil)
            .environmentObject(AccountViewModel.mocked())
    }
}
