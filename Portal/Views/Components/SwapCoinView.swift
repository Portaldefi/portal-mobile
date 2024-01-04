//
//  SwapCoinView.swift
//  Portal
//
//  Created by farid on 20.12.2023.
//

import SwiftUI

struct SwapCoinView: View {
    let coin: Coin?
    
    var body: some View {
        HStack(spacing: 6) {
            if let coin = coin {
                CoinImageView(size: 16, url: coin.icon)
                Text(coin.code.uppercased())
                    .font(.Main.fixed(.bold, size: 18))
                    .foregroundColor(.white)
            } else {
                Text("select")
                    .font(.Main.fixed(.bold, size: 12))
                    .foregroundColor(.white)
                    .frame(height: 32)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(Color(red: 0.125, green: 0.125, blue: 0.125))
        }
    }
}


#Preview {
    SwapCoinView(coin: .bitcoin())
}
