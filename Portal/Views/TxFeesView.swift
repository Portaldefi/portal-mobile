//
//  TxFeesView.swift
// Portal
//
//  Created by farid on 10/2/22.
//

import SwiftUI
import PortalUI

struct TxFeesView: View {
    let fees: String
    let coin: String
    
    var body: some View {
        HStack {
            Text("Fees")
                .font(.Main.fixed(.monoBold, size: 14))
                .foregroundColor(Palette.grayScaleAA)
            Spacer()
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(fees)
                    .font(.Main.fixed(.monoRegular, size: 16))
                Text(coin)
                    .font(.Main.fixed(.monoMedium, size: 12))
            }
            .foregroundColor(Palette.grayScaleF4)
        }
        .frame(height: 72)
    }
}

struct TxFeesView_Previews: PreviewProvider {
    static var previews: some View {
        TxFeesView(fees: "0.000000134", coin: "btc")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
