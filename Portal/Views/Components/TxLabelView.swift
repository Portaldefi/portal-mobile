//
//  TxLabelView.swift
// Portal
//
//  Created by farid on 10/3/22.
//

import SwiftUI
import PortalUI

struct TxLabelView: View {
    var searchContext: String? = nil
    let label: TxLabel
    
    var body: some View {
        if searchContext?.lowercased() == label.label.lowercased() {
            Text(label.label)
                .font(.Main.fixed(.monoMedium, size: 14))
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(red: 255/255, green: 189/255, blue: 20/255, opacity: 1))
                .cornerRadius(8)
        } else {
            HighlightedText(
                text: label.label,
                textColor: Palette.grayScaleF4,
                highlight: searchContext,
                font: .Main.fixed(.monoMedium, size: 14)
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Palette.grayScale4A)
            .cornerRadius(8)
        }
    }
}

struct TxLabelView_Previews: PreviewProvider {
    static var previews: some View {
        TxLabelView(label: TxLabel(label: "Preview"))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
