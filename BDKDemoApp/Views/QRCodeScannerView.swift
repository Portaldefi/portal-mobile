//
//  QRCodeScannerView.swift
//  BDKDemoApp
//
//  Created by farid on 8/11/22.
//

import SwiftUI
import CodeScanner
import PortalUI

struct QRCodeScannerView: View {
    var body: some View {
        ZStack {
            Color(red: 26/255, green: 26/255, blue: 26/255, opacity: 1).ignoresSafeArea()
            
            VStack {
                ZStack {
                    CodeScannerView(codeTypes: [.qr], scanMode: .continuous, simulatedData: "sajdhsadjgewriusdakdjhsaiufewkjhfg") { response in
                        if case let .success(result) = response {
                            print(response)
                            //scannedCode = result.string
                            //isPresentingScanner = false
                        }
                    }
                    CameraTargetOverlayView()
                }
                .cornerRadius(12)
                .padding()
                
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(height: 128)
                    .ignoresSafeArea()
            }
        }
    }
}

struct QRCodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeScannerView()
            .previewLayout(PreviewLayout.sizeThatFits)
    }
}
