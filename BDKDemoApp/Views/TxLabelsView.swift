//
//  TxLabelsView.swift
//  BDKDemoApp
//
//  Created by farid on 10/3/22.
//

import SwiftUI
import PortalUI

struct TxLabelsView: View {
    let labels: [TxLable]
    
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
            TxLable(label: "Taxes"),
            TxLable(label: "Buisness"),
            TxLable(label: "Friend"),
            TxLable(label: "Do Not Spend"),
            TxLable(label: "Savings"),
            TxLable(label: "Food")
        ])
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
