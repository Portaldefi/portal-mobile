//
//  WalletItemView.swift
//  Portal
//
//  Created by farid on 25/8/22.
//

import SwiftUI
import PortalUI
import Factory

struct WalletItemView: View {
    private let showBalance: Bool
    private let lightning: Bool

    @ObservedObject private var viewModel: WalletItemViewModel
    
    init(viewModel: WalletItemViewModel, showBalance: Bool = true, lightning: Bool = false) {
        self.viewModel = viewModel
        self.showBalance = showBalance
        self.lightning = lightning
    }
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4.2) {
                    HStack(spacing: 8) {
                        CoinImageView(
                            size: 32,
                            url: viewModel.coin.icon,
                            placeholderForegroundColor: Color.gray
                        )
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(viewModel.coin.name)
                                .font(.Main.fixed(.monoBold, size: 16))
                                .foregroundColor(.white)
                                .frame(height: 16)
                            Text("\(viewModel.coin.code) • \(viewModel.coin.network)")
                                .font(.Main.fixed(.monoRegular, size: 14))
                                .foregroundColor(Palette.grayScale6A)
                        }
                    }
                }
            }
            
            Spacer()
            
            if viewModel.coin == .lightningBitcoin() {
                if !viewModel.lightningKit.usableChannels.isEmpty {
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
                                Text(viewModel.coin.unit)
                                    .font(.Main.fixed(.monoRegular, size: 14))
                                    .foregroundColor(Palette.grayScaleAA)
                                Spacer()
                            }
                            .frame(width: 42)
                            Text(viewModel.fiatCurrency.code)
                                .font(.Main.fixed(.monoRegular, size: 14))
                                .foregroundColor(Palette.grayScale6A)
                                .offset(y: 3)
                        }
                    }
                } else if !viewModel.lightningKit.allChannels.isEmpty {
                    Text("Waiting for Confirmations")
                        .multilineTextAlignment(.center)
                        .font(.Main.fixed(.monoRegular, size: 16))
                        .foregroundColor(.yellow)
                        .padding(.trailing, 12)
                } else {
                    Text("Setup a Channel")
                        .multilineTextAlignment(.center)
                        .font(.Main.fixed(.monoRegular, size: 16))
                        .foregroundColor(Palette.grayScale6A)
                        .padding(.trailing, 12)
                        .frame(width: 80)
                }
            } else {
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
                                Text(viewModel.coin.unit)
                                    .font(.Main.fixed(.monoRegular, size: 14))
                                    .foregroundColor(Palette.grayScaleAA)
                                Spacer()
                            }
                            .frame(width: 42)
                            Text(viewModel.fiatCurrency.code)
                                .font(.Main.fixed(.monoRegular, size: 14))
                                .foregroundColor(Palette.grayScale6A)
                                .offset(y: 3)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .frame(height: 70)
    }
}

struct WalletItemView_Previews: PreviewProvider {
    static var previews: some View {
        WalletItemView(viewModel: WalletItem.mocked.viewModel)
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
    }
}
