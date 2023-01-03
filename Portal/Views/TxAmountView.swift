//
//  TxAmountView.swift
// Portal
//
//  Created by farid on 10/2/22.
//

import SwiftUI
import PortalUI

struct TxAmountView: View {
    let amount: String
    let value: String
    let code: String
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(amount)
                    .font(.Main.fixed(.monoBold, size: 32))
                    .foregroundColor(Palette.grayScaleEA)
                    .frame(height: 26)
                
                Text(code)
                    .font(.Main.fixed(.monoRegular, size: 18))
                    .foregroundColor(Palette.grayScale6A)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.Main.fixed(.monoMedium, size: 16))
                    .foregroundColor(Palette.grayScale6A)
                
                Text("usd")
                    .font(.Main.fixed(.monoMedium, size: 12))
                    .foregroundColor(Palette.grayScale6A)
            }
        }
    }
}

struct TxAmountView_Previews: PreviewProvider {
    static var previews: some View {
        TxAmountView(amount: "0.000055", value: "1.24", code: "btc")
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
