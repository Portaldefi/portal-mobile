//
//  QRReaderRootView.swift
//  Portal
//
//  Created by farid on 2/7/23.
//

import SwiftUI
import Factory

struct QRCodeReaderRootView: View {
    private let navigationStack: NavigationStackView<QRCodeReaderView>
    
    init(config: QRScannerConfig, completion: @escaping (QRCodeItem) ->() = { _ in }) {
        navigationStack = NavigationStackView<QRCodeReaderView>(
            configurator: SendViewNavigationConfig(),
            rootView: QRCodeReaderView(config: config) { completion($0) }
        )
    }
    
    var body: some View {
        navigationStack.zIndex(1).navigationBarBackButtonHidden()
    }
}

struct QRCodeReaderRootView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeReaderRootView(config: .universal)
    }
}

