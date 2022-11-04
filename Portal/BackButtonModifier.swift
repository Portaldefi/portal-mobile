//
//  BackButtonModifier.swift
//  Portal
//
//  Created by farid on 7/22/22.
//

import SwiftUI

struct BackButtonModifier: ViewModifier {
    @Environment(\.presentationMode) var presentation
    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
               .toolbar(content: {
                  ToolbarItem (placement: .navigation)  {
                     Image(systemName: "arrow.left")
                     .foregroundColor(.white)
                     .shadow(color: Color("Shadow"), radius: 2, x: 2, y: 2)
                     .onTapGesture {
                         self.presentation.wrappedValue.dismiss()
                     }
                  }
               })
    }
}

struct BackButtonMod_Previews: PreviewProvider {
    static var previews: some View {
        Text("Heyy").modifier(BackButtonModifier())
    }
}

