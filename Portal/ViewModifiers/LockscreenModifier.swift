//
//  LockscreenModifier.swift
//  Portal
//
//  Created by farid on 27.06.2023.
//

import SwiftUI
import Factory

struct LockScreenModifier: ViewModifier {
    @ObservedObject var viewState = Container.viewState()

    func body(content: Content) -> some View {
        content.fullScreenCover(isPresented: $viewState.walletLocked) {
            PincodeView()
        }
    }
}
