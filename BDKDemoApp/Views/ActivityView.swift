//
//  ActivityView.swift
//  BDKDemoApp
//
//  Created by farid on 23/8/22.
//

import SwiftUI
import Factory

struct ActivityView: View {
    @ObservedObject private var viewState = Container.viewState()
    @State private var qrScannerOpened = false
    
    var body: some View {
        Text("Activity")
            .onChange(of: viewState.showScanner, perform: { newValue in
                qrScannerOpened.toggle()
            })
            .sheet(isPresented: $qrScannerOpened, onDismiss: {

            }) {
                QRCodeScannerView { item in
                    print(item)
                }
            }
    }
}
