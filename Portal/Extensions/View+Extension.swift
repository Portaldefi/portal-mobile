//
//  View+Extension.swift
//  Portal
//
//  Created by farid on 9/2/22.
//

import SwiftUI

extension View {
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(_ condition: Bool, then trueContent: (Self) -> TrueContent, else falseContent: (Self) -> FalseContent) -> some View {
        if condition {
            trueContent(self)
        } else {
            falseContent(self)
        }
    }

    @ViewBuilder
    func `if`<TrueContent: View>(_ condition: Bool, then trueContent: (Self) -> TrueContent) -> some View {
        if condition {
            trueContent(self)
        } else {
            self
        }
    }
    
    func textFieldAlert(isPresented: Binding<Bool>, content: @escaping () -> TextFieldAlert) -> some View {
        TextFieldWrapper(
            isPresented: isPresented,
            presentingView: self,
            content: content
        )
    }
    
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}
