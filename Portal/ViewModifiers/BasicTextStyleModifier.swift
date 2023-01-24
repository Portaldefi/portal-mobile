//
//  BasicTextStyleModifier.swift
//  Portal
//
//  Created by farid on 7/21/22.
//

import SwiftUI

struct BasicTextStyle: ViewModifier {
    var big = false
    var white = false
    var bold = false
    func body(content: Content) -> some View {
        content
            .font(.system(size: big ? 32 : 14, design: .monospaced).weight(bold ? .bold : .regular))
            .foregroundColor(white ? Color.white : Color("Shadow"))
            
    }
}
extension Text {
    func textStyle<Style: ViewModifier>(_ style: Style) -> some View {
        ModifiedContent(content: self, modifier: style)
    }
}

struct BasicTextStyle_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello").textStyle(BasicTextStyle())
    }
}

struct BackgroundColorModifier: ViewModifier {
    let color: Color
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            color.ignoresSafeArea()
            content
        }
    }
}

extension View {
    func filledBackground<Style: ViewModifier>(_ style: Style) -> some View {
        ModifiedContent(content: self, modifier: style)
    }
}

struct BackgroundColorModifier_Previews: PreviewProvider {
    static var previews: some View {
        RoundedRectangle(cornerRadius: 12)
            .filledBackground(BackgroundColorModifier(color: Color.yellow))
    }
}
