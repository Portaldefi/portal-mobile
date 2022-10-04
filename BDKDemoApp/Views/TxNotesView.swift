//
//  TxNotesView.swift
//  BDKDemoApp
//
//  Created by farid on 10/3/22.
//

import SwiftUI
import PortalUI

struct TxNotesView: View {
    let notes: String
    
    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(alignment: .firstTextBaseline) {
                Text("Notes")
                    .font(.Main.fixed(.monoBold, size: 14))
                    .foregroundColor(Palette.grayScaleAA)
                    .frame(width: 50)
                Spacer()
                Text(notes)
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
        TxNotesView(notes: "Design Services. Payment 1/5 and some longer text to test the expandability of the component|")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
