//
//  TxIDView.swift
// Portal
//
//  Created by farid on 10/2/22.
//

import SwiftUI
import PortalUI

struct TxIDView: View {
    let txID: String
    let explorerURL: URL?
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Transaction ID")
                .font(.Main.fixed(.monoBold, size: 14))
                .foregroundColor(Palette.grayScaleAA)
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Text(txID)
                    .font(.Main.fixed(.monoRegular, size: 16))
                    .foregroundColor(Palette.grayScaleF4)
                
                Button {
                    if let url = explorerURL {
#if os(iOS)
                        UIApplication.shared.open(url)
#elseif os(macOS)
                        NSWorkspace.shared.open(url)
#endif
                    }
                } label: {
                    RadialGradient.main
                        .mask {
                            HStack(spacing: 4) {
                                Asset.explorerIcon
                                    .resizable()
                                    .frame(width: 19, height: 19)
                                Text("Block Explorer")
                                    .font(.Main.fixed(.monoBold, size: 14))
                            }
                        }
                }
                .frame(width: 141, height: 19)
            }
        }
        .frame(height: 79)
    }
}

struct TxIDView_Previews: PreviewProvider {
    static var previews: some View {
        TxIDView(txID: "239y...928ye", explorerURL: nil)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
