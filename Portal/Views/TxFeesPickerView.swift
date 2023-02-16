//
//  TxFeesPickerView.swift
//  Portal
//
//  Created by farid on 2/16/23.
//

import SwiftUI
import PortalUI

struct TxFeesPickerView: View {
    let coin: Coin
    let recommendedFees: RecomendedFees

    @Binding var feeRate: TxFees
    
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Change Fee")
                    .font(.Main.fixed(.monoBold, size: 16))
                    .foregroundColor(Palette.grayScaleF4)
                
                HStack {
                    PButton(config: .onlyLabel("Cancel"), style: .free, size: .small, applyGradient: true, enabled: true) {
                        onDismiss()
                    }
                    .frame(width: 58)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 62)
            
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        Palette.grayScale20
                    )
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        feeRate = .fast
                        onDismiss()
                    } label: {
                        HStack {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Palette.grayScale2A, lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundColor(Palette.grayScale10)
                                        .frame(width: 22, height: 22)
                                    
                                    if feeRate == .fast {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                RadialGradient.main
                                            )
                                            .frame(width: 22, height: 22)
                                    }
                                }
                                
                                Text("Fast")
                                    .font(.Main.fixed(.monoBold, size: 16))
                                    .foregroundColor(Palette.grayScaleF4)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("~10 mins")
                                    .font(.Main.fixed(.monoRegular, size: 16))
                                    .foregroundColor(Palette.grayScaleF4)
                                Text(recommendedFees.fastestFee.double.formattedString(.coin(coin), decimals: 8) + "\(coin.type == .bitcoin ? " sat/vByte" : " eth")")
                                    .font(.Main.fixed(.monoRegular, size: 14))
                                    .foregroundColor(Palette.grayScale8A)
                            }
                        }
                        .frame(height: 72)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                    
                    Button {
                        feeRate = .normal
                        onDismiss()
                    } label: {
                        HStack {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Palette.grayScale2A, lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundColor(Palette.grayScale10)
                                        .frame(width: 22, height: 22)
                                    
                                    if feeRate == .normal {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                RadialGradient.main
                                            )
                                            .frame(width: 22, height: 22)
                                    }
                                }
                                
                                Text("Normal")
                                    .font(.Main.fixed(.monoBold, size: 16))
                                    .foregroundColor(Palette.grayScaleF4)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("~30 mins")
                                    .font(.Main.fixed(.monoRegular, size: 16))
                                    .foregroundColor(Palette.grayScaleF4)
                                Text(recommendedFees.halfHourFee.double.formattedString(.coin(coin), decimals: 8) + "\(coin.type == .bitcoin ? " sat/vByte" : " eth")")
                                    .font(.Main.fixed(.monoRegular, size: 14))
                                    .foregroundColor(Palette.grayScale8A)
                            }
                        }
                        .frame(height: 72)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                    
                    Button {
                        feeRate = .slow
                        onDismiss()
                    } label: {
                        HStack {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Palette.grayScale2A, lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundColor(Palette.grayScale10)
                                        .frame(width: 22, height: 22)
                                    
                                    if feeRate == .slow {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                RadialGradient.main
                                            )
                                            .frame(width: 22, height: 22)
                                    }
                                }
                                
                                Text("Slow")
                                    .font(.Main.fixed(.monoBold, size: 16))
                                    .foregroundColor(Palette.grayScaleF4)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("~60 mins")
                                    .font(.Main.fixed(.monoRegular, size: 16))
                                    .foregroundColor(Palette.grayScaleF4)
                                Text(recommendedFees.hourFee.double.formattedString(.coin(.bitcoin()), decimals: 8) + "\(coin.type == .bitcoin ? " sat/vByte" : " eth")")
                                    .font(.Main.fixed(.monoRegular, size: 14))
                                    .foregroundColor(Palette.grayScale8A)
                            }
                        }
                        .frame(height: 72)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    
                    Divider()
                    
                    Button {
                        feeRate = .custom
                        onDismiss()
                    } label: {
                        HStack {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Palette.grayScale2A, lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundColor(Palette.grayScale10)
                                        .frame(width: 22, height: 22)
                                    
                                    if feeRate == .custom {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                RadialGradient.main
                                            )
                                            .frame(width: 22, height: 22)
                                    }
                                }
                                
                                Text("Custom")
                                    .font(.Main.fixed(.monoBold, size: 16))
                                    .foregroundColor(Palette.grayScaleF4)
                            }
                            
                            Spacer()
                            
                            Asset.chevronRightIcon
                                .foregroundColor(Palette.grayScale4A)
                        }
                        .frame(height: 72)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 300)
            .padding(.horizontal, 16)
            .padding(.bottom, 58)
        }
        .background(
            Palette.grayScale2A.edgesIgnoringSafeArea(.bottom).cornerRadius(20, corners: .allCorners)
        )
    }
}

struct TxFeesPickerView_Previews: PreviewProvider {
    static var previews: some View {
        TxFeesPickerView(
            coin: .bitcoin(),
            recommendedFees: RecomendedFees(fastestFee: 100, halfHourFee: 80, hourFee: 40),
            feeRate: .constant(.normal),
            onDismiss: {}
        )
    }
}
