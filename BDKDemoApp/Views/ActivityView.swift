//
//  ActivityView.swift
//  BDKDemoApp
//
//  Created by farid on 23/8/22.
//

import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var viewState: ViewState
    @State private var qrScannerOpened = false
    
    var body: some View {
        Text("Activity")
            .onChange(of: viewState.showScanner, perform: { newValue in
                qrScannerOpened.toggle()
            })
            .sheet(isPresented: $qrScannerOpened, onDismiss: {

            }) {
                QRCodeScannerView()
            }
    }
}
