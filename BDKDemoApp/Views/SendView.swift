//
//  SendView.swift
//  BDKDemoApp
//
//  Created by farid on 7/25/22.
//

import SwiftUI
import Combine
import BitcoinAddressValidator
import Factory
import PortalUI

class SendViewViewModel: ObservableObject {
    private let item: QRCodeItem?
    @Published var to = String()
    @Published var amount = String()
    
    init(item: QRCodeItem?) {
        self.item = item
    }
}

struct SendView: View {
    private let qrCodeItem: QRCodeItem?
    private let walletItems: [WalletItem]
    
    @State private var to: String
    @State private var amount: String
    @State private var qrScannerOpened = false
    @State private var selectedItem: WalletItem?
    
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
    @ObservedObject private var viewModel = Container.accountViewModel()
    @ObservedObject private var viewState = Container.viewState()
    @FocusState private var isFocused: Bool
    
    init(walletItems: [WalletItem], qrCodeItem: QRCodeItem?) {
        UITableView.appearance().backgroundColor = .clear
        
        self.walletItems = walletItems
        self.qrCodeItem = qrCodeItem
        
        switch qrCodeItem?.type {
        case .bip21(let address, let amount, _):
            _to = State(initialValue: address)
            guard let amount = amount else {
                _amount = State(initialValue: String())
                return
            }
            _amount = State(initialValue: amount)
            _selectedItem = State(initialValue: walletItems.first)
        default:
            _to = State(initialValue: String())
            _amount = State(initialValue: String())
        }
    }
    
    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 10/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack {
                    if selectedItem != nil {
                        HStack {
                            PButton(config: .onlyIcon(Asset.arrowLeftIcon), style: .free, size: .big, enabled: selectedItem != nil) {
                                withAnimation {
                                    selectedItem = nil
                                }
                            }
                            .frame(width: 20)
                            
                            Spacer()
                        }
                    }
                    
                    Text("Send")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .frame(height: 62)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                        
                        ScrollView {
                            VStack {
                                if let item = selectedItem {
                                    WalletItemView(item: item)
                                        .padding(.horizontal)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(red: 42/255, green: 42/255, blue: 42/255), lineWidth: 1)
                                        )
                                        .contentShape(Rectangle())
                                } else {
                                    ForEach(walletItems) { item in
                                        WalletItemView(item: item)
                                            .padding(.horizontal)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color(red: 42/255, green: 42/255, blue: 42/255), lineWidth: 1)
                                            )
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                withAnimation {
                                                    selectedItem = item
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        .frame(height: CGFloat(walletItems.count) * 66)
                    }
                    
                    if selectedItem != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Amount")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                Spacer()
                                PButton(config: .onlyLabel("Max"), style: .free, size: .small, enabled: false) {
                                    
                                }
                                .frame(width: 40)
                            }
                            
                            TextField("Required", text: $amount)
                                .focused($isFocused)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.numberPad)
                                .font(Font.system(size: 16, weight: .bold, design: .monospaced))
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            Color(red: 26/255, green: 26/255, blue: 26/255)
                                        )
                                )
                                .onReceive(Just(amount)) { newValue in
                                    let filtered = newValue.filter { "0123456789".contains($0) }
                                    if filtered != newValue {
                                        self.amount = filtered
                                    }
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Address")
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                Spacer()
                                PButton(config: .onlyLabel("Select from Contacts"), style: .free, size: .small, enabled: false) {
                                    
                                }
                                .frame(width: 200)
                            }
                            
                            ZStack {
                                TextField("Required", text: $to)
                                    .focused($isFocused)
                                    .disableAutocorrection(true)
                                    .textInputAutocapitalization(.never)
                                    .font(Font.system(size: 16, weight: .bold, design: .monospaced))
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                Color(red: 26/255, green: 26/255, blue: 26/255)
                                            )
                                    )
                                
                                HStack {
                                    Spacer()
                                    PButton(config: .onlyIcon(Asset.qrIcon), style: .free, size: .big, enabled: true) {
                                        qrScannerOpened.toggle()
                                    }
                                    .frame(width: 25, height: 25)
                                }
                                .padding(.horizontal)
                            }
                            
                            HStack {
                                PButton(config: .labelAndIconLeft(label: "Annotate", icon: Asset.pencilIcon), style: .free, size: .small, enabled: false) {
                                    
                                }
                                PButton(config: .labelAndIconLeft(label: "Tag", icon: Asset.tagIcon), style: .free, size: .small, enabled: false) {
                                    
                                }
                            }
                            .padding()
                        }
                    }
                }
                .onTapGesture {
                    isFocused = false
                }
                
                if selectedItem != nil {
                    Button {
                        viewModel.send(to: to, amount: amount, completion: { error in
                            guard let error = error else {
                                showConfirmationAlert()
                                return
                            }
                            signalAlert.send(error)
                        })
                    } label: {
                        Text("Continue")
                            .foregroundColor(.black)
                            .font(.system(size: 22, design: .monospaced))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(Color.blue)
                            .background(in: RoundedRectangle(cornerRadius: 10))
                            .frame(height: 60)
                    }
                    .disabled(!BitcoinAddressValidator.isValid(address: to) || (Double(amount) ?? 0) == 0)
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                }
                Spacer()
            }
            .modifier(BackButtonModifier())
            .padding(.horizontal, 16)
        }
        .navigationTitle("Send Bitcoin")
        .onReceive(signalAlert) { error in
            showAlert(error: error)
        }
        .sheet(isPresented: $qrScannerOpened, onDismiss: {
            
        }) {
            QRCodeScannerView { item in
                switch item.type {
                case .bip21(let address, let amount, _):
                    to = address
                    guard let amount = amount else { return }
                    self.amount = amount
                default:
                    break
                }
            }
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
        SendView(walletItems: [WalletItem(description: "Bitcoin", balance: "0.00001", value: "0.5")], qrCodeItem: nil)
            .environmentObject(AccountViewModel.mocked())
    }
}
