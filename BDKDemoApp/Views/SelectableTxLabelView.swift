//
//  SelectableTxLabelView.swift
//  BDKDemoApp
//
//  Created by farid on 10/3/22.
//

import SwiftUI
import PortalUI

struct SelectableTxLabelView: View {
    let item: TxLable
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 16) {
                if isSelected {
                    ZStack {
                        Circle()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Palette.grayScale2A)
                        
                        RadialGradient.main.mask {
                            Circle().frame(width: 22, height: 22)
                        }
                        
                        Asset.checkIcon
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.black)
                    }
                    .frame(width: 24, height: 24)
                } else {
                    ZStack {
                        Circle()
                            .frame(width: 24, height: 24)
                            .foregroundColor(Palette.grayScale2A)
                        Circle()
                            .foregroundColor(Palette.grayScale10)
                            .frame(width: 22, height: 22)
                    }
                    .frame(width: 24, height: 24)
                }
                
                Text(item.label)
                    .font(.Main.fixed(.monoBold, size: 16))
                    .foregroundColor(.white)
            }
            .frame(height: 56)
        }
    }
}

struct SelectableTxLabelView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SelectableTxLabelView(item: TxLable(label: "Buisness"), isSelected: false)
                .padding()
            SelectableTxLabelView(item: TxLable(label: "Dev"), isSelected: true)
                .padding()
        }
            .previewLayout(.sizeThatFits)
    }
}

