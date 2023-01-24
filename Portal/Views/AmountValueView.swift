//
//  AmountView.swift
// Portal
//
//  Created by farid on 10/24/22.
//

import SwiftUI
import PortalUI

struct AmountValueView: View {
    @ObservedObject var exchanger: Exchanger
    
    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(alignment: .firstTextBaseline) {
                Text("Amount")
                    .font(.Main.fixed(.monoBold, size: 14))
                    .foregroundColor(Palette.grayScaleAA)
                    .padding(.horizontal, 8)
                    .offset(y: -10)
                Spacer()
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(exchanger.baseAmountString)
                            .font(.Main.fixed(.monoBold, size: 32))
                            .foregroundColor(Palette.grayScaleF4)

                        Text(exchanger.quoteAmountString)
                            .font(.Main.fixed(.monoRegular, size: 16))
                            .foregroundColor(Palette.grayScale6A)
                            .offset(y: -8)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(exchanger.base.unit.lowercased())
                            .font(.Main.fixed(.monoRegular, size: 18))
                            .foregroundColor(Palette.grayScale6A)

                        Text(exchanger.quote.code.lowercased())
                            .font(.Main.fixed(.monoMedium, size: 12))
                            .foregroundColor(Palette.grayScale6A)
                    }
                }
            }
            .padding(.vertical, 16)
            
            Asset.chevronRightIcon
                .foregroundColor(Palette.grayScale4A)
                .offset(x: 20)
        }
        .frame(height: 82)
    }
}

struct AmountValueView_Previews: PreviewProvider {
    static var previews: some View {
        AmountValueView(exchanger: Exchanger.mocked())
            .padding()
            .previewLayout(.sizeThatFits)
    }
}

