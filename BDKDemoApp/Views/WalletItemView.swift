//
//  WalletItemView.swift
//  BDKDemoApp
//
//  Created by farid on 25/8/22.
//

import SwiftUI
import PortalUI

struct WalletItemView: View {
    let item: WalletItem
    var body: some View {
        HStack {
            VStack(spacing: 12) {
                VStack(spacing: 4.2) {
                    HStack(spacing: 6) {
                        CoinImageView(
                            size: 24,
                            url: item.viewModel.coin.icon,
                            placeholderForegroundColor: Color.gray
                        )
                        Text(item.viewModel.coin.name)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(Palette.grayScaleCA)
                            .frame(height: 16)
                        Spacer()
                    }
                    HStack(spacing: 4) {
                        Text("on")
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Palette.grayScale6A)
                            .frame(height: 17)
                        item.viewModel.coin.chainIcon.resizable()
                            .frame(width: 12, height: 12)
                            .foregroundColor(Palette.grayScale8A)
                        Text(item.viewModel.coin.description)
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Palette.grayScale6A)
                            .frame(height: 17)
                        Spacer()
                    }
                }
            }
            Spacer()
            HStack(spacing: 6) {
                VStack(alignment: .trailing, spacing: 0) {
                    Text(item.viewModel.balanceString)
                        .font(.Main.fixed(.monoBold, size: 20))
                        .foregroundColor(Palette.grayScaleEA)
                    Text(item.viewModel.valueString)
                        .font(.Main.fixed(.monoMedium, size: 16))
                        .foregroundColor(Palette.grayScale6A)
                }
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(item.viewModel.coin.unit.lowercased())
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Palette.grayScaleAA)
                        Spacer()
                    }
                    .frame(width: 40)
                    Text("usd")
                        .font(.Main.fixed(.monoMedium, size: 12))
                        .foregroundColor(Palette.grayScale6A)
                        .offset(y: 7)
                }
            }
        }
        .frame(height: 70)
    }
}

struct WalletItemView_Previews: PreviewProvider {
    static var previews: some View {
        WalletItemView(item: WalletItem.mockedBtc)
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
    }
}
