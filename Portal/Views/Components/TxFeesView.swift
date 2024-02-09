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
    let source: TxSource
    
    var title: String {
        switch source {
        case .bitcoin:
            return "Fees"
        case .ethereum, .erc20:
            return "Fees"
        case .lightning, .swap:
            return "Network Fees"
        }
    }
    
    private var coin: String {
        switch source {
        case .bitcoin, .lightning:
            return Coin.bitcoin().code
        case .ethereum, .erc20:
            return Coin.ethereum().code
        case .swap(let base, _):
            return base.code
        }
    }
    
    var body: some View {
        HStack {
            Text(title)
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
        .frame(height: 52)
    }
}

struct TxFeesView_Previews: PreviewProvider {
    static var previews: some View {
        TxFeesView(fees: "0.000000134", source: .bitcoin)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
