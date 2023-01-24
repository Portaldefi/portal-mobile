//
//  WalletItemView.swift
//  Portal
//
//  Created by farid on 25/8/22.
//

import SwiftUI
import PortalUI

struct WalletItemView: View {
    private let showBalance: Bool
    @ObservedObject private var viewModel: WalletItemViewModel
    
    init(viewModel: WalletItemViewModel, showBalance: Bool = true) {
        self.viewModel = viewModel
        self.showBalance = showBalance
    }
    
    var body: some View {
        HStack {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4.2) {
                    HStack(spacing: 6) {
                        CoinImageView(
                            size: 24,
                            url: viewModel.coin.icon,
                            placeholderForegroundColor: Color.gray
                        )
                        Text(viewModel.coin.name)
                            .font(.Main.fixed(.monoBold, size: 16))
                            .foregroundColor(.white)
                            .frame(height: 16)
                    }
                    HStack(spacing: 4) {
                        Text("on")
                            .font(.Main.fixed(.monoMedium, size: 14))
                            .foregroundColor(Palette.grayScale6A)
                            .frame(height: 17)
                        viewModel.coin.chainIcon.resizable()
                            .frame(width: 12, height: 12)
                            .foregroundColor(Palette.grayScale8A)
                        Text(viewModel.coin.description)
                            .font(.Main.fixed(.monoMedium, size: 14))
                            .foregroundColor(Palette.grayScale6A)
                            .frame(height: 17)
                    }
                }
            }
            Spacer()
            if showBalance {
                HStack(spacing: 6) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(viewModel.balanceString)
                            .font(.Main.fixed(.monoBold, size: 20))
                            .foregroundColor(Palette.grayScaleEA)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text(viewModel.valueString)
                            .font(.Main.fixed(.monoMedium, size: 16))
                            .foregroundColor(Palette.grayScale6A)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(viewModel.coin.unit.lowercased())
                                .font(.Main.fixed(.monoRegular, size: 14))
                                .foregroundColor(Palette.grayScaleAA)
                            Spacer()
                        }
                        .frame(width: 40)
                        Text("usd")
                            .font(.Main.fixed(.monoRegular, size: 14))
                            .foregroundColor(Palette.grayScale6A)
                            .offset(y: 4)
                    }
                }
            }
        }
        .frame(height: 70)
    }
}

struct WalletItemView_Previews: PreviewProvider {
    static var previews: some View {
        WalletItemView(viewModel: WalletItem.mockedBtc.viewModel)
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
    }
}
