//
//  TextFieldWrapper.swift
//  BDKDemoApp
//
//  Created by farid on 10/3/22.
//

import SwiftUI

struct TextFieldWrapper<PresentingView: View>: View {
    @Binding var isPresented: Bool
    let presentingView: PresentingView
    let content: () -> TextFieldAlert
    
    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                content().dismissable($isPresented)
            }
            presentingView
        }
    }
}
