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
    @State private var overlayOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color(red: 26/255, green: 26/255, blue: 26/255, opacity: 1).ignoresSafeArea()
            
            VStack {
                ZStack {
                    CodeScannerView(codeTypes: [.qr], simulatedData: "bitcoin:BC1QYLH3U67J673H6Y6ALV70M0PL2YZ53TZHVXGG7U?amount=0.00001&label=sbddesign%3A%20For%20lunch%20Tuesday&message=For%20lunch%20Tuesday&lightning=LNO1PG257ENXV4EZQCNEYPE82UM50YNHXGRWDAJX283QFWDPL28QQMC78YMLVHMXCSYWDK5WRJNJ36JRYG488QWLRNZYJCZS") { response in
                        if case let .success(result) = response {
                            let items = QRCodeParser.current.parse(result.string)
                            for item in items {
                                print(item)
                            }
                        }
                    }
                    CameraTargetOverlayView()
                        .opacity(overlayOpacity)
                        .onAppear {
                            withAnimation {
                                overlayOpacity = 1
                            }
                        }
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
