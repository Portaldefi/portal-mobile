//
//  QRCodeScannerView.swift
//  BDKDemoApp
//
//  Created by farid on 8/11/22.
//

import SwiftUI
import CodeScanner
import PortalUI
import Factory

struct QRCodeScannerView: View {
    private let qrCodeSimulatedData = "bitcoin:BC1QYLH3U67J673H6Y6ALV70M0PL2YZ53TZHVXGG7U?amount=0.00001&label=sbddesign%3A%20For%20lunch%20Tuesday&message=For%20lunch%20Tuesday&lightning=LNO1PG257ENXV4EZQCNEYPE82UM50YNHXGRWDAJX283QFWDPL28QQMC78YMLVHMXCSYWDK5WRJNJ36JRYG488QWLRNZYJCZS"
    @State private var importFromLibrary = false
    @State private var torchOn  = false
    @State private var scanState: ScanState = .detecting
    @State private var detectedItems: [QRCodeItem] = []
    @State private var showingNoQRAlert = false
    @State private var showingNotSupportedQRAlert = false
    @State private var qrItem: QRCodeItem?
    
    @ObservedObject var viewModel = Container.sendViewModel()
    
    enum ScanState {
        case detecting, detected
    }
    
    @Environment(\.presentationMode) var presentation
    
    private let detected: (QRCodeItem) -> ()
    private let onClose: () -> ()
    
    init(detected: @escaping (QRCodeItem) -> (), onClose: @escaping () -> () = {}) {
        self.detected = detected
        self.onClose = onClose
    }
    
    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 10/255, opacity: 1).ignoresSafeArea()
            
            VStack {
                ZStack {
                    ZStack(alignment: .bottom) {
                        ZStack {
                            CodeScannerView(
                                codeTypes: [.qr],
                                scanMode: .continuous,
                                simulatedData: qrCodeSimulatedData,
                                isTorchOn: torchOn,
                                isGalleryPresented: $importFromLibrary
                            ) { response in
                                if case let .success(result) = response {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        detectedItems = QRCodeParser.current.parse(result.string)
                                        scanState = .detected
                                    }
                                } else if case let .failure(error) = response {
                                    switch error {
                                    case .badInput:
                                        break
                                    case .badOutput:
                                        showingNoQRAlert.toggle()
                                    case .permissionDenied:
                                        break
                                    case .initError(_):
                                        break
                                    }
                                } else {
                                    withAnimation {
                                        scanState = .detecting
                                    }
                                }
                            }
                            
#if targetEnvironment(simulator)
                            RoundedRectangle(cornerRadius: 12)
                                .foregroundColor(.gray)
                                .zIndex(-1)
#else
                            CameraTargetOverlayView()
#endif
                        }
                        
                        switch scanState {
                        case .detecting:
                            Text("Scan QR code to detect items")
                                .font(.system(size: 12, design: .monospaced))
                                .padding(8)
                                .frame(height: 33)
                                .frame(maxWidth: .infinity)
                                .background(Color(red: 10/255, green: 10/255, blue: 10/255, opacity: 1))
                                .foregroundColor(Color(red: 138/255, green: 138/255, blue: 138/255, opacity: 1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 42/255, green: 42/255, blue: 42/255, opacity: 1), lineWidth: 1)
                                )
                                .padding([.bottom, .horizontal], 8)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        case .detected:
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Detected Items")
                                        .font(.system(size: 12, design: .monospaced))
                                        .padding(8)
                                        .frame(height: 33)
                                        .foregroundColor(Color(red: 138/255, green: 138/255, blue: 138/255, opacity: 1))
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .background(Color(red: 10/255, green: 10/255, blue: 10/255))
                                
                                Divider()
                                
                                ForEach(detectedItems) {
                                    QRCodeItemView(item: $0)
                                        .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
                                }
                            }
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(red: 42/255, green: 42/255, blue: 42/255, opacity: 1), lineWidth: 1)
                            )
                            .padding([.bottom, .horizontal], 8)
                        }
                    }
                }
                .cornerRadius(12)
                .padding(16)
                
                HStack {
                    PButton(config: .onlyIcon(Asset.galeryIcon), style: .free, size: .big, enabled: true) {
                        importFromLibrary.toggle()
                    }
                    .frame(width: 60, height: 60)
                    
                    Spacer()
                    
                    PButton(config: .onlyIcon(Asset.lightningIcon), style: .free, size: .big, enabled: true) {
                        torchOn.toggle()
                    }
                    .frame(width: 60, height: 60)
                    
                    Spacer()
                    
                    PButton(config: .onlyIcon(Asset.xIcon), style: .outline, size: .big, enabled: true) {
                        onClose()
                    }
                    .frame(width: 60, height: 60)
                }
                .padding(.horizontal, 24)
                .frame(height: 84)
                .ignoresSafeArea()
            }
        }
        .navigationBarHidden(true)
        .alert(isPresented: $showingNoQRAlert) {
            Alert(title: Text("No QR Code Found"),
                  message: Text("Make sure the image contains a valid QR Code clearly visible."),
                  dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showingNotSupportedQRAlert) {
            Alert(title: Text("Not Supported Address or Wallet Detected"),
                  message: Text("\nThe QR Code doesn’t contain a supported address type.\n\nSuppported Addresses:\n• Bitcoin Legacy\n• Bitcoin Segwit\n• Bitcoin Taproot\n• Lightning Invoice\n• Lightning Offer\n• Lightning Node ID\n• Lightning Address\n\nSuppported Wallet Keys:\nBitcoin Wallet Public Key\nBitcoin Wallet Private Key"),
                  dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func QRCodeItemView(item: QRCodeItem) -> some View {
        Button {
            detectedItems.removeAll()
            scanState = .detecting
            detected(item)
        } label: {
            ZStack(alignment: .bottom) {
                HStack {
                    VStack(spacing: 12) {
                        VStack(spacing: 4.2) {
                            HStack(spacing: 6) {
                                RoundedRectangle(cornerRadius: 8)
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(Color.green)
                                Text(item.title)
                                    .font(.system(size: 14, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255, opacity: 1))
                                    .frame(height: 16)
                                Spacer()
                            }
                            HStack(spacing: 6) {
                                Spacer()
                                    .frame(width: 16, height: 16)
                                
                                switch item.type {
                                case .bip21, .privKey, .pubKey:
                                    Text("on")
                                        .font(.system(size: 12, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                                        .frame(height: 17)
                                    Asset.chainIcon
                                        .resizable()
                                        .frame(width: 12, height: 12)
                                case .bolt11, .bolt12:
                                    Text("on")
                                        .font(.system(size: 12, design: .monospaced))
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                                        .frame(height: 17)
                                    Asset.lightningIcon
                                        .resizable()
                                        .frame(width: 12, height: 12)
                                case .unsupported:
                                    EmptyView()
                                }
                                
                                Text(item.description)
                                    .font(.system(size: 12, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                                    .frame(height: 17)
                                    .foregroundColor(Color(red: 138/255, green: 138/255, blue: 138/255, opacity: 1))
                                Spacer()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Asset.chevronRightIcon
                        .foregroundColor(Color(red: 74/255, green: 74/255, blue: 74/255))
                }
                .padding(.horizontal)
                .frame(height: 59)
                
                Divider()
                    .frame(maxWidth: .infinity, maxHeight: 1)
            }
            .background(Color(red: 26/255, green: 26/255, blue: 26/255))
        }
    }
}

struct QRCodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeScannerView(detected: {_ in })
            .previewLayout(PreviewLayout.sizeThatFits)
    }
}
