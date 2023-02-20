//
//  EditableTextFieldView.swift
// Portal
//
//  Created by farid on 10/3/22.
//

import SwiftUI
import PortalUI

struct EditableTextFieldView: View {
    let description: String
    let text: String
    
    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(alignment: .firstTextBaseline) {
                Text(description)
                    .font(.Main.fixed(.monoBold, size: 14))
                    .foregroundColor(Palette.grayScaleAA)
                    .padding(.trailing, 8)
                Spacer()
                Text(text)
                    .font(.Main.fixed(.monoBold, size: 14))
                    .foregroundColor(Palette.grayScaleF4)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 16)
            
            Asset.chevronRightIcon
                .foregroundColor(Palette.grayScale4A)
                .offset(x: 20)
        }
    }
}

struct TxNotesView_Previews: PreviewProvider {
    static var previews: some View {
        EditableTextFieldView(description: "notes", text: "Design Services. Payment 1/5 and some longer text to test the expandability of the component|")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
