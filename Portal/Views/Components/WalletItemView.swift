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
        switch viewModel.coin.type {
        case .lightningBitcoin:
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 0) {
                        CoinImageView(
                            size: 32,
                            url: viewModel.coin.icon,
                            placeholderForegroundColor: Color.gray
                        )
                        .padding(.trailing, 8)
                        
                        VStack(alignment: .leading, spacing: 5) {
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
                
                Spacer()
                
                if
                    let channel = viewModel.lightningKit.allChannels.first,
                    let confirmations = channel.getConfirmations(),
                    let requiredConfirmations = channel.getConfirmationsRequired(),
                    confirmations < requiredConfirmations
                {
                    Text("Waiting for Confirmations")
                        .multilineTextAlignment(.center)
                        .font(.Main.fixed(.monoRegular, size: 16))
                        .foregroundColor(.yellow)
                        .padding(.trailing, 12)
                    
                } else if
                    let channel = viewModel.lightningKit.allChannels.first,
                    let confirmations = channel.getConfirmations(),
                    let requiredConfirmations = channel.getConfirmationsRequired(),
                    confirmations >= requiredConfirmations
                {
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
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(viewModel.coin.unit)
                                .font(.Main.fixed(.monoRegular, size: 14))
                                .foregroundColor(Palette.grayScaleAA)
                            
                            Text(viewModel.fiatCurrency.code)
                                .font(.Main.fixed(.monoRegular, size: 14))
                                .foregroundColor(Palette.grayScale6A)
                                .offset(y: 3)
                        }
                    }
                } else {
                    Text("Setup a Channel")
                        .multilineTextAlignment(.center)
                        .font(.Main.fixed(.monoRegular, size: 16))
                        .foregroundColor(Palette.grayScale6A)
                        .padding(.trailing, 12)
                        .frame(width: 80)
                }
            }
            .padding(.vertical, 12)
            .frame(height: 70)
        default:
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    CoinImageView(
                        size: 32,
                        url: viewModel.coin.icon,
                        placeholderForegroundColor: Color.gray
                    )
                    .padding(.trailing, 8)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 0) {
                            Text(viewModel.coin.name)
                                .font(.Main.fixed(.monoBold, size: 16))
                                .foregroundColor(.white)
                                .frame(height: 16)
                            
                            Spacer()
                            
                            if showBalance {
                                Text(viewModel.balanceString)
                                    .font(.Main.fixed(.monoBold, size: 20))
                                    .foregroundColor(Palette.grayScaleEA)
                                    .minimumScaleFactor(0.5)
                                    .lineLimit(1)
                                
                                Text(viewModel.coin.unit)
                                    .font(.Main.fixed(.monoRegular, size: 14))
                                    .foregroundColor(Palette.grayScaleAA)
                                    .padding(.leading, 4)
                                    .offset(y: 1)
                            }
                        }
                        
                        HStack(spacing: 0) {
                            Text("\(viewModel.coin.code) • \(viewModel.coin.network)")
                                .font(.Main.fixed(.monoRegular, size: 14))
                                .foregroundColor(Palette.grayScale6A)
                            
                            Spacer()
                            
                            if showBalance {
                                Text(viewModel.valueString)
                                    .font(.Main.fixed(.monoMedium, size: 16))
                                    .foregroundColor(Palette.grayScale6A)
                                
                                Text(viewModel.fiatCurrency.code)
                                    .font(.Main.fixed(.monoRegular, size: 14))
                                    .foregroundColor(Palette.grayScale6A)
                                    .padding(.leading, 4)
                                    .offset(y: 1)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .frame(height: 70)
        }
    }
}

struct WalletItemView_Previews: PreviewProvider {
    static var previews: some View {
        WalletItemView(viewModel: WalletItem.mockedPortal.viewModel)
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
    }
}
