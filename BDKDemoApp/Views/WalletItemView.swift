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
                        RoundedRectangle(cornerRadius: 8)
                            .frame(width: 16, height: 16)
                            .foregroundColor(Color.green)
                        Text("Bitcoin")
                            .font(.system(size: 14, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255, opacity: 1))
                            .frame(height: 16)
                        Spacer()
                    }
                    HStack(spacing: 2) {
                        Spacer()
                            .frame(width: 16, height: 16)
                        Text("on")
                            .font(.system(size: 12, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                            .frame(height: 17)
                        Asset.chainIcon.resizable()
                            .frame(width: 12, height: 12)
                            .foregroundColor(Color(red: 138/255, green: 138/255, blue: 138/255, opacity: 1))
                        Text("Chain")
                            .font(.system(size: 12, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                            .frame(height: 17)
                        Spacer()
                    }
                }
            }
            Spacer()
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Spacer()
                    Text("\(item.balance)")
                        .font(.system(size: 18, design: .monospaced))
                        .fontWeight(.semibold)
                    Text("sats")
                        .font(.system(size: 16, design: .monospaced))
                }
                .foregroundColor(Color(red: 202/255, green: 202/255, blue: 202/255, opacity: 1))
                .frame(height: 22)
                
                HStack(spacing: 10) {
                    Spacer()
                    Text(item.value)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                    Text("usd")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(red: 106/255, green: 106/255, blue: 106/255, opacity: 1))
                }
                .frame(height: 22)
            }
        }
        .frame(height: 66)
    }
}

struct WalletItemView_Previews: PreviewProvider {
    static var previews: some View {
        WalletItemView(item: WalletItem(description: "on Chain", balance: "0.0001", value: "0.5"))
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding()
    }
}
