//
//  TxLabelView.swift
// Portal
//
//  Created by farid on 10/3/22.
//

import SwiftUI
import PortalUI

struct TxLabelView: View {
    let label: TxLable
    
    var body: some View {
        Text(label.label)
            .font(.Main.fixed(.monoMedium, size: 14))
            .foregroundColor(Palette.grayScaleF4)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Palette.grayScale4A)
            .cornerRadius(8)
    }
}

struct TxLabelView_Previews: PreviewProvider {
    static var previews: some View {
        TxLabelView(label: TxLable(label: "Preview"))
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
