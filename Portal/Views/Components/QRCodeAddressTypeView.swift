//
//  QRCodeAddressTypeView.swift
//  Portal
//
//  Created by farid on 2/20/23.
//

import SwiftUI
import PortalUI

struct QRCodeAddressTypeView: View {
    let coin: Coin
    
    @Binding var addressType: BTCQRCodeAddressType
    
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Choose Address Type")
                .font(.Main.fixed(.monoBold, size: 16))
                .foregroundColor(Palette.grayScaleF4)
                .frame(height: 62)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(BTCQRCodeAddressType.allCases, id: \.title) { type in
                    Button {
                        addressType = type
                        onDismiss()
                    } label: {
                        switch type {
                        case .lightning:
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Palette.grayScale2A, lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundColor(Palette.grayScale10)
                                        .frame(width: 22, height: 22)
                                    
                                    if addressType == .lightning {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                RadialGradient.main
                                            )
                                            .frame(width: 22, height: 22)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(type.title)
                                            .font(.Main.fixed(.monoBold, size: 18))
                                            .foregroundColor(Palette.grayScaleF4)
                                        
                                        TxLabelView(label: TxLable(label: "Recommended"))
                                    }
                                    
                                    Text(type.description)
                                        .font(.Main.fixed(.monoRegular, size: 14))
                                        .foregroundColor(Palette.grayScaleAA)
                                }
                            }
                            .frame(height: 106)
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                        case .onChain:
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Palette.grayScale2A, lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundColor(Palette.grayScale10)
                                        .frame(width: 22, height: 22)
                                    
                                    if addressType == .onChain {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                RadialGradient.main
                                            )
                                            .frame(width: 22, height: 22)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(type.title)
                                            .font(.Main.fixed(.monoBold, size: 18))
                                            .foregroundColor(Palette.grayScaleF4)
                                    }
                                    
                                    Text(type.description)
                                        .font(.Main.fixed(.monoRegular, size: 14))
                                        .foregroundColor(Palette.grayScaleAA)
                                }
                            }
                            .frame(height: 106)
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                        case .unified:
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Palette.grayScale2A, lineWidth: 2)
                                        .frame(width: 24, height: 24)
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .foregroundColor(Palette.grayScale10)
                                        .frame(width: 22, height: 22)
                                    
                                    if addressType == .unified {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                RadialGradient.main
                                            )
                                            .frame(width: 22, height: 22)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 12) {
                                        Text(type.title)
                                            .font(.Main.fixed(.monoBold, size: 18))
                                            .foregroundColor(Palette.grayScaleF4)
                                        
                                        Text("Experimental")
                                            .font(.Main.fixed(.monoMedium, size: 14))
                                            .foregroundColor(Palette.grayScale6A)
                                    }
                                    
                                    Text(type.description)
                                        .font(.Main.fixed(.monoRegular, size: 14))
                                        .foregroundColor(Palette.grayScaleAA)
                                }
                            }
                            .frame(height: 110)
                            .padding(.horizontal, 16)
                            .contentShape(Rectangle())
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if type != .unified {
                        Divider()
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16).fill(Palette.grayScale20)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 58)
        }
        .background(
            Palette.grayScale2A.cornerRadius(20, corners: .allCorners)
        )
    }
}

struct QRCodeAddressTypeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeAddressTypeView(
            coin: .bitcoin(),
            addressType: .constant(.lightning),
            onDismiss: {}
        )
    }
}
