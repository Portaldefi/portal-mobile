//
//  TxLabelsView.swift
// Portal
//
//  Created by farid on 10/3/22.
//

import SwiftUI
import PortalUI

struct TxLabelsView: View {
    let labels: [TxLabel]
    
    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(alignment: .top) {
                Text("Labels")
                    .font(.Main.fixed(.monoBold, size: 14))
                    .foregroundColor(Palette.grayScaleAA)
                    .frame(width: 51)
                    .offset(y: 4)
                Spacer()
                
                WrappedHStack(labels) { label in
                    TxLabelView(label: label)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 16)
            
            Asset.chevronRightIcon
                .foregroundColor(Palette.grayScale4A)
                .offset(x: 20)
        }
    }
}

struct TxLabelsView_Previews: PreviewProvider {
    static var previews: some View {
        TxLabelsView(labels: [
            TxLabel(label: "Taxes"),
            TxLabel(label: "Buisness"),
            TxLabel(label: "Friend"),
            TxLabel(label: "Do Not Spend"),
            TxLabel(label: "Savings"),
            TxLabel(label: "Food")
        ])
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
