//
//  QRCodeFullStringView.swift
//  Portal
//
//  Created by farid on 2/21/23.
//

import SwiftUI
import PortalUI

struct QRCodeFullStringView: View {
    let string: String
    let addressType: BTCQRCodeAddressType
    
    var onCopy: () -> Void
    var onDismiss: () -> Void
    
    private var title: String {
        switch addressType {
        case .lightning:
            return "Lightning Invoice"
        case .onChain:
            return "Bitcoin Address"
        case .unified:
            return "Unified"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    PButton(config: .onlyIcon(Asset.copyIcon), style: .free, size: .big, color: Palette.grayScale8A, enabled: true) {
                        onCopy()
                    }
                    .frame(width: 18, height: 32)
                    
                    Spacer()
                    
                    PButton(config: .onlyIcon(Asset.xIcon), style: .free, size: .big, color: Palette.grayScale8A, enabled: true) {
                        onDismiss()
                    }
                    .frame(width: 14, height: 14)
                }
                .padding(.leading, 22)
                .padding(.trailing, 24)
                
                Text(title)
                    .font(.Main.fixed(.monoBold, size: 16))
                    .foregroundColor(Palette.grayScaleF4)
                    .frame(height: 62)
            }
            
            Text(string)
                .font(.Main.fixed(.monoRegular, size: 16))
                .foregroundColor(Palette.grayScaleAA)
                .padding(.horizontal, 16)
                .padding(.bottom, 58)
        }
        .background(
            Palette.grayScale2A.edgesIgnoringSafeArea(.bottom).cornerRadius(20, corners: .allCorners)
        )
    }
}

struct QRCodeFullStringView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeFullStringView(
            string: "LNBC10U1P3PJ257PP5YZTKWJCZ5FTL5LAXKAV23ZMZEKAW37ZK6KMV80PK4XAEV5QHTZ7QDPDWD3XGER9WD5KWM36YPRX7U3QD36KUCMGYP282ETNV3SHJCQZPGXQYZ5VQSP5USYC4LK9CHSFP53KVCNVQ456GANH60D89REYKDNGSMTJ6YW3NHVQ9QYYSSQJCEWM5CJWZ4A6RFJX77C490YCED6PEMK0UPKXHY89CMM7SCT66K8GNEANWYKZGDRWRFJE69H9U5U0W57RRCSYSAS7GADWMZXC8C6T0SPJAZUP6",
            addressType: .lightning) {
            
        } onDismiss: {}
    }
}
